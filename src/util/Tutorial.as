package util {
    import flash.utils.*;
    import flash.text.*;
    import flash.events.*;
    import flash.geom.Point;
    import flash.display.*;
    
    import net.flashpunk.FP;
    import net.flashpunk.utils.Input;
    import com.bit101.components.*;
    
    import com.gskinner.motion.*;
    import com.gskinner.motion.plugins.*;
    import com.gskinner.motion.easing.*;
    
    import world.*;
    import gfx.*;
    import components.*;
    import reactor.Reactor;
    import world.entities.*;
    
    public class Tutorial {
        [Embed(source = '/assets/fonts/FFFHARMO.ttf', embedAsCFF="false", fontFamily='FFF Harmony')] 
        private const HARMONY:Class;
        [Embed(source="/assets/sprites/dwn_arrow.png")]  
        private const DOWNARROW:Class;
        [Embed(source="/assets/sprites/right_arrow.png")]  
        private const RIGHTARROW:Class;
        [Embed(source="/assets/sprites/mouse_on.png")]
        private const MOUSE_ON:Class;
        [Embed(source="/assets/sprites/mouse_off.png")]
        private const MOUSE_OFF:Class;
        [Embed(source="/assets/data/Tutorial.xml", mimeType="application/octet-stream")] 
        private static const TUTORIALTEXT:Class;
        
        private var _map:Map;
        private var _current_point:int;
        private var _path:Vector.<Point>;
        
        private var _panel:RoundedPanel;
        private var _text:Text;
        
        private var _tutorialtext:XML;
        
        private var _fort_sighted:Boolean;
        
        private var _mouse:Bitmap;
        private var _mouse_off:BitmapData;
        private var _mouse_on:BitmapData;
        private var _mouse_tween:Timer;
        
        private var _arrow:Bitmap;
        private var _arrow_tween:GTween;
        
        private var _drag_tween:GTween;
        
        private var _waypoint_handler:Function;
        private var _waypoint_holder:MapPoint;
        
        public function Tutorial(m:Map):void {
            _map = m;
            _current_point = 0;
            _path = Vector.<Point>([]);
            _panel = new RoundedPanel(Hud.instance, 50, 210, 20);
            _text = new Text(_panel, 5, 5, "");
            _text.selectable = _text.editable = false;
            _fort_sighted = false;
            _tutorialtext = new XML(new TUTORIALTEXT());
            _tutorialtext.prettyIndent = 0;
            _tutorialtext.prettyPrinting = false;
            _panel.y = 238 - _panel.height/2;
            _map.shipSighted.addOnce(handleShipSighted);
            _map.fortSighted.addOnce(handleFortSighted);
            _map.shipDamaged.addOnce(handleShipDamaged);
            _map.fortExplode.addOnce(handleFortExploded);
            _map.waypointAdded.add(handleWaypoint);
            _map.heroDeployed.addOnce(handleHeroDeployed);
            _map.started.addOnce(gameStarted);
            _mouse_off = new MOUSE_OFF().bitmapData;
            _mouse_on = new MOUSE_ON().bitmapData;
            _mouse = new Bitmap(_mouse_off);
            _mouse.visible = false;
            _mouse_tween = new Timer(750);
            _mouse_tween.addEventListener(TimerEvent.TIMER, pulseMouse);
            _mouse_tween.start();
            Hud.instance.addChild(_mouse);
            stepOne();
        }
        
        public function get points():Vector.<Point> { return _path; }
        
        public function clear():void {
            _panel.visible = false;
            if (_arrow_tween) _arrow_tween.end();
            if (_drag_tween) _drag_tween.end();
            _drag_tween = _arrow_tween = null;
            if (Hud.instance.contains(_arrow)) {
                Hud.instance.removeChild(_arrow);
            }
            _mouse_tween.stop();
            _mouse_tween.removeEventListener(TimerEvent.TIMER, pulseMouse);
            if (Hud.instance.contains(_mouse)) {
                Hud.instance.removeChild(_mouse);
            }
            Hud.instance.pathLayer.deleteFlag = true;
        }
        
        public function reset():void {
            _map.shipSighted.removeAll();
            _map.fortSighted.removeAll();
            _map.shipDamaged.removeAll();
            _map.fortExplode.removeAll();
            Hud.instance.pathLayer.waypointAdded.remove(handleWaypoint);
            _map.heroDeployed.removeAll();
            _map.started.removeAll();
            Hud.instance.pathLayer.checkZone = true;
            clear();
        }
        
        private function handleBadPath():void {
            trace("handleBadPath");
        }
        
        private function handleWaypoint(w:MapPoint):void {
            trace("handleWaypoint");
            if (_waypoint_handler == null) return;
            _waypoint_handler(w);
        }
        
        private function gameStarted():void {
            _panel.visible = false;
            for (var i:int=0; i < _panel.numChildren; i++) {
                if (_panel.getChildAt(i) is PushButton) _panel.removeChildAt(i);
            }
            clear();
        }
        
        private function handleShipSighted(s:Ship):void {
            trace("handleShipSighted");
            Main.changeRate(0);
            _panel.alpha = .85;
            _panel.width = 225; _panel.height = 150, 
            _panel.x = s.x + 35, _panel.y = s.y - (_panel.height/2);
            _text.x = 9, _text.width = 215; _text.height = 140;
            _text.text = _tutorialtext.text.(@step == "shipSighted");
            _map.doCheckInput = false;
            var okButton:PushButton = new PushButton(_panel, 0, 0, "Ok", function(evt:MouseEvent):void {
                okButton.enabled = false;
                _panel.visible = false;
                Main.changeRate(1.5);
                Hud.instance.clear();
                if (_panel.contains(okButton)) _panel.removeChild(okButton);
                Reactor.callLater(function():void {
                    _map.doCheckInput = true;
                });
            });
            okButton.alpha = 1;
            okButton.x = (_panel.width/2) - (okButton.width/2);
            okButton.y = _panel.height - okButton.height - 10;
            _panel.draw();
            _text.draw();
            var g:Graphics = Hud.instance.graphics;
            g.lineStyle(1, 0xffffff, 1);
            g.drawCircle(s.x, s.y-11, 24);
            Reactor.callLater(function():void {
                _panel.visible = true;
                Hud.instance.addChild(_panel);
            });
        }
        
        private function handleHeroDeployed(s:Ship):void {
            Main.changeRate(0);
            _map.doCheckInput = false;
            _panel.alpha = .85;
            _panel.width = 225; _panel.height = 110, 
            _panel.x = s.x + 35, _panel.y = s.y - (_panel.height/2);
            _text.x = 9, _text.width = 215; _text.height = 100;
            _text.text = _tutorialtext.text.(@step == "heroDeployed");
            var okButton:PushButton = new PushButton(_panel, 0, 0, "Next >>", function(evt:MouseEvent):void {
                okButton.enabled = false;
                _panel.visible = false;
                if (_panel.contains(okButton)) _panel.removeChild(okButton);
                heroDeployedStepTwo(s);
            });
            okButton.alpha = 1;
            okButton.x = (_panel.width/2) - (okButton.width/2);
            okButton.y = _panel.height - okButton.height - 10;
            _panel.draw();
            _text.draw();
            var g:Graphics = Hud.instance.graphics;
            g.lineStyle(1, 0xffffff, 1);
            g.drawCircle(s.x, s.y-11, 24);
            Reactor.callLater(function():void {
                _panel.visible = true;
                Hud.instance.addChild(_panel);
            });
        }
        
        private function heroDeployedStepTwo(s:Ship):void {
            Main.changeRate(0);
            _panel.alpha = .85;
            _panel.width = 225; _panel.height = 110, 
            _panel.x = s.x + 45, _panel.y = s.y - 100;
            _text.x = 9, _text.width = 215; _text.height = 110;
            _text.text = _tutorialtext.text.(@step == "heroDeployedStepTwo");
            _panel.draw();
            _text.draw();
            Hud.instance.clear();
            var g:Graphics = Hud.instance.graphics;
            g.beginFill(0x22ff22, .5);
            g.drawCircle(435, 225, 10);
            _arrow = Hud.instance.addChild(new DOWNARROW()) as Bitmap;
            _arrow.x = 435 - (_arrow.width/2), _arrow.y = 225 - _arrow.height - 10;
            _mouse.x = 455, _mouse.y = 225 - _mouse.height/2;
            _mouse.visible = true;
            pulseArrow(_arrow, _arrow.x, _arrow.y, _arrow.x, _arrow.y-15);
            _mouse_tween = new Timer(750);
            _mouse_tween.addEventListener(TimerEvent.TIMER, pulseMouse);
            _mouse_tween.start();
            Hud.instance.addChild(_mouse);
            _map.moveCommand.addOnce(heroDeployedStepThree);
            Reactor.callLater(function():void {
                _panel.visible = true;
                Hud.instance.addChild(_panel);
                _map.doCheckInput = true;
            });
        }
        
        private function heroDeployedStepThree(p:Point):void {
            clear();
            var airship:Airship = (Main.ships[0] as Airship); 
            if (Point.distance(p, new Point(435, 225)) <= 15.0) {
                _panel.visible = false;
                _text.text = _tutorialtext.text.(@step == "heroDeployedStepThree");
                _text.height = 170, _panel.height = 125;
                var okButton:PushButton = new PushButton(_panel, 0, 0, "Ok", function(evt:MouseEvent):void {
                    okButton.enabled = false;
                    _panel.visible = false;
                    Main.changeRate(1.5);
                    Hud.instance.clear();
                    if (_panel.contains(okButton)) _panel.removeChild(okButton);
                    Reactor.callLater(function():void {_map.doCheckInput = true;});
                });
                okButton.alpha = 1;
                okButton.x = (_panel.width/2) - (okButton.width/2);
                okButton.y = _panel.height - okButton.height - 10;
                _panel.draw();
                _text.draw();
                Reactor.callLater(function():void {_panel.visible = true});
                _map.doCheckInput = false;
            } else {
                Hud.instance.showMessage("Move your flagship to the green circle by clicking on it.");
                _map.moveCommand.addOnce(heroDeployedStepThree);
            }
        }
        
        private function handleFortSighted(f:Fort):void {
            clear();
            trace("handleFortSighted");
            if (_fort_sighted) return;
            Main.changeRate(0);
            _panel.alpha = .85;
            _panel.width = 225; _panel.height = 120, 
            _panel.x = f.x + 25, _panel.y = f.y - (_panel.height/2);
            _text.x = 9, _text.width = 215; _text.height = 110;
            _text.text = _tutorialtext.text.(@step == "fortSighted");
            _fort_sighted = true;
            _map.doCheckInput = false;
            var okButton:PushButton = new PushButton(_panel, 0, 0, "Ok", function(evt:MouseEvent):void {
                okButton.enabled = false;
                _panel.visible = false;
                Main.changeRate(1.5);
                Hud.instance.clear();
                if (_panel.contains(okButton)) _panel.removeChild(okButton);
                Reactor.callLater(function():void {
                    _map.doCheckInput = true;
                });
            });
            okButton.alpha = 1;
            okButton.x = (_panel.width/2) - (okButton.width/2);
            okButton.y = _panel.height - okButton.height - 10;
            _panel.draw();
            _text.draw();
            var g:Graphics = Hud.instance.graphics;
            g.lineStyle(1, 0xffffff, 1);
            g.drawCircle(f.x, f.y-8, 15);
            Reactor.callLater(function():void {
                _panel.visible = true;
                Hud.instance.addChild(_panel);
            });
        }
        
        private function handleShipDamaged(s:Ship):void {
            trace("handleShipDamaged");
        }
        
        private function handlePathComplete():void {
            clear();
            _panel.x = 225; _panel.y = 155, _panel.alpha = 1;
            _panel.width = 350; _panel.height = 165;
            _text.x = 9, _text.width = 340; _text.height = 120;
            _text.text = _tutorialtext.text.(@step == "3");
            _panel.draw();
            _text.draw();
            Reactor.callLater(function():void {
                _panel.visible = true;
                Hud.instance.addChild(_panel);
            });        
        }
        
        private function handleShipClicked(s:Ship):void {
            trace("handleShipClicked");
        }
        
        private function handleFortExploded(f:Fort):void {
            trace("handleFortExploded");
            clear();
            Main.changeRate(0);
            _panel.alpha = .85;
            _panel.width = 225; _panel.height = 110, 
            _panel.x = f.x + 25, _panel.y = f.y - (_panel.height/2);
            _text.x = 9, _text.width = 215; _text.height = 80;
            _text.text = _tutorialtext.text.(@step == "fortExploded");
            _fort_sighted = true;
            _map.doCheckInput = false;
            var okButton:PushButton = new PushButton(_panel, 0, 0, "Ok", function(evt:MouseEvent):void {
                okButton.enabled = false;
                _panel.visible = false;
                Main.changeRate(1.5);
                Hud.instance.clear();
                if (_panel.contains(okButton)) _panel.removeChild(okButton);
                Reactor.callLater(function():void {
                    _map.doCheckInput = true;
                }); 
            });
            okButton.alpha = 1;
            okButton.x = (_panel.width/2) - (okButton.width/2);
            okButton.y = _panel.height - okButton.height - 10;
            _panel.draw();
            _text.draw();
            var g:Graphics = Hud.instance.graphics;
            g.lineStyle(1, 0xffffff, 1);
            g.drawCircle(f.x, f.y-8, 15);
            Reactor.callLater(function():void {
                _panel.visible = true;
                Hud.instance.addChild(_panel);
            });        
        }
        
        private function pulseMouse(evt:TimerEvent):void {
            var phase:Boolean = (evt.target as Timer).currentCount % 2 == 0;
            _mouse.bitmapData = (phase) ? _mouse_on : _mouse_off;
        }
        
        private function pulseArrow(arrow:Bitmap, start_x:int, start_y:int, end_x:int, end_y:int):void {
            _arrow_tween = new GTween(arrow, .75, {'x': end_x, 'y': end_y}, {'ease':Linear.easeNone, 'onComplete': function():void {
                pulseArrow(arrow, end_x, end_y, start_x, start_y);
            }});
        }
        
        public function stepOne():void {
            _panel.width = 300, _panel.height = 135, _panel.alpha = .85;
            _panel.y = Main.level.start.y - int(135/2);
            _text.width = 290; _text.height = 115;
            _text.text = _tutorialtext.text.(@step == "1");
            var g:Graphics = Hud.instance.graphics;
            g.beginFill(0x22ff22, .5);
            g.drawCircle(435, 225, 10);
            _arrow = Hud.instance.addChild(new DOWNARROW()) as Bitmap;
            _arrow.x = 435 - (_arrow.width/2), _arrow.y = 225 - _arrow.height - 10;
            _mouse.x = 455, _mouse.y = 225 - _mouse.height/2;
            _mouse.visible = true;
            pulseArrow(_arrow, _arrow.x, _arrow.y, _arrow.x, _arrow.y-15);
            var okButton:PushButton = new PushButton(_panel, 0, 0, "or Skip Tutorial", function(evt:MouseEvent):void {
                okButton.enabled = false;
                _panel.visible = false;
                Main.changeRate(1.5);
                Hud.instance.clear();
                if (_panel.contains(okButton)) _panel.removeChild(okButton);
                reset();
                (FP.world as Map).tutorialSkipped();
            });
            okButton.alpha = 1;
            okButton.x = (_panel.width/2) - (okButton.width/2);
            okButton.y = _panel.height - okButton.height - 10;
            _panel.draw();
            _text.draw();
            _panel.visible = false;
            Reactor.callLater(function():void {
                _panel.visible = true;
                Hud.instance.addChild(_panel);
                Hud.instance.showHelp(null);
            });
            Hud.instance.pathLayer.deleteFlag = false;
            Hud.instance.pathLayer.checkZone = false;
            _waypoint_handler = function(p:MapPoint):void {
                if (Point.distance(p.point, new Point(435, 225)) <= 12) {
                    _waypoint_holder = p;
                    stepTwo();
                } else {
                    Hud.instance.pathLayer.removeWaypoint(p);
                    Hud.instance.showMessage("Please skip the tutorial or click the green circle to continue.");
                }
            }
        }
        
        private function dragMouse(mouse:Bitmap, start_x:int, end_x:int, start_y:int, end_y:int):void {
            var self:Tutorial = this;
            _drag_tween = new GTween(mouse, 1.5, {'x':end_x, 'y':end_y}, {'ease':Linear.easeNone, 'onComplete': function():void {
                mouse.x = start_x, mouse.y = start_y;
                Reactor.callLater(dragMouse, self, [mouse, start_x, end_x, start_y, end_y]);
            }});
        }
        
        public function stepTwo():void {
            clear();
            for (var i:int=0; i < _panel.numChildren; i++) {
                if (_panel.getChildAt(i) is PushButton) _panel.removeChildAt(i);
            }
            Hud.instance.clear();
            var g:Graphics = Hud.instance.graphics;
            g.beginFill(0x22ff22, .5);
            g.drawCircle(335, 225, 10);
            _arrow = Hud.instance.addChild(new DOWNARROW()) as Bitmap;
            _arrow.x = 335 - (_arrow.width/2), _arrow.y = 225 - _arrow.height - 10;
            pulseArrow(_arrow, _arrow.x, _arrow.y, _arrow.x, _arrow.y-15);
            _panel.x = 450; _panel.y = 200;
            _panel.width = 300; _panel.height = 125;
            _text.width = 290; _text.height = 120;
            _text.text = _tutorialtext.text.(@step == "2");
            _panel.draw();
            _text.draw();
            var mouse:Bitmap = new MOUSE_ON();
            mouse.x = 435 - mouse.width/2, mouse.y = 240;
            dragMouse(mouse, mouse.x, 335-mouse.width/2, mouse.y, mouse.y);
            Hud.instance.addChild(mouse);
            Hud.instance.pathLayer.deleteFlag = false;
            _map.waypointAdded.remove(handleWaypoint);
            Hud.instance.pathLayer.waypointAdded.remove(handleWaypoint);
            Hud.instance.pathLayer.waypointAdded.add(function(m:MapPoint):void {
                trace("what the fuck.");
                Hud.instance.showMessage("Please drag the first waypoint to the green circle to the left.");
                Hud.instance.pathLayer.removeWaypoint(m);
            });
            _waypoint_handler = function(p:MapPoint):void {
                if (p.point.equals(_waypoint_holder.point) && Point.distance(p.point, new Point(335, 225)) <= 12) {
                    Hud.instance.removeChild(mouse);
                    stepThree();
                } else {
                    if (!p.point.equals(_waypoint_holder.point)) Hud.instance.pathLayer.removeWaypoint(p);
                    Hud.instance.showMessage("Please drag the first waypoint to the green circle to the left.");
                }
            }
            Hud.instance.pathLayer.dragStopped.add(_waypoint_handler);
            Reactor.callLater(function():void {
                _panel.visible = true;
                Hud.instance.addChild(_panel);
            });
        }
        
        public function stepThree():void {
            clear();
            _map.waypointAdded.add(handleWaypoint);
            Hud.instance.pathLayer.waypointAdded.removeAll();
            Hud.instance.pathLayer.waypointAdded.add(handleWaypoint)
            Hud.instance.pathLayer.dragStopped.remove(_waypoint_handler);
            for (var i:int=0; i < _panel.numChildren; i++) {
                if (_panel.getChildAt(i) is PushButton) _panel.removeChildAt(i);
            }
            Hud.instance.clear();
            _panel.x = 350; _panel.y = 200;
            _panel.width = 300; _panel.height = 105;
            _text.width = 290; _text.height = 95;
            _text.text = _tutorialtext.text.(@step == "3");
            _panel.draw();
            _text.draw();
            Hud.instance.pathLayer.deleteFlag = true;
            _waypoint_handler = function(p:MapPoint):void {
                Hud.instance.pathLayer.removeWaypoint(p);
                Hud.instance.showMessage("Delete the waypoint you created by clicking it and dragging it to the trash can.");
            }
            Hud.instance.pathLayer.pointDeleted.addOnce(function(mp:MapPoint):void {
                stepFour();
            });
            Reactor.callLater(function():void {
                _panel.visible = true;
                Hud.instance.addChild(_panel);
            });
        }
        
        public function stepFour():void {
            clear();
            Hud.instance.pathLayer.dragStopped.remove(_waypoint_handler);
            for (var i:int=0; i < _panel.numChildren; i++) {
                if (_panel.getChildAt(i) is PushButton) _panel.removeChildAt(i);
            }
            Hud.instance.clear();
            _panel.x = 350; _panel.y = 200;
            _panel.width = 300; _panel.height = 115;
            _text.width = 290; _text.height = 130;
            _text.text = _tutorialtext.text.(@step == "4");
            _panel.draw();
            _text.draw();
            _waypoint_handler = null;
            _arrow = Hud.instance.addChild(new RIGHTARROW()) as Bitmap;
            _arrow.x = Main.level.end.x - 80, _arrow.y = Main.level.end.y - _arrow.height + 10;
            Hud.instance.pathLayer.checkZone = true;
            pulseArrow(_arrow, _arrow.x, _arrow.y, _arrow.x-15, _arrow.y);
            Hud.instance.pathLayer.pointDeleted.removeAll();
            var okButton:PushButton = new PushButton(_panel, 0, 0, "Ok, Let's do this.", function(evt:MouseEvent):void {
                okButton.enabled = false;
                _panel.visible = false;
                Main.changeRate(1.5);
                Hud.instance.clear();
                if (_panel.contains(okButton)) _panel.removeChild(okButton);
                Hud.instance.showMessage("Create a path from the entry point to the white extraction zone on the right.");
                Hud.instance.pathLayer.checkZone = true;
            });
            okButton.alpha = 1;
            okButton.x = (_panel.width/2) - (okButton.width/2);
            okButton.y = _panel.height - okButton.height - 10;
            _map.doCheckInput = false;
            Reactor.callLater(function():void {
                _panel.visible = true;
                Hud.instance.addChild(_panel);
            });
        }
    }
}