package gfx {
    import flash.net.*;
    import flash.text.*;
    import flash.geom.*;
    import flash.utils.*;
    import flash.filters.*;
    import flash.events.*;
    import flash.display.*;
    import flash.display.Sprite;
    import flash.text.TextFormat;

    import reactor.*;
    import world.*;
    import world.entities.*;
    import util.*;
    import components.*;
    
    import org.osflash.signals.Signal;
    
    import lib.swfstats.*;
    import com.gskinner.motion.*;
    import com.gskinner.motion.plugins.*;
    import com.gskinner.motion.easing.*;
    import com.bit101.components.*;
    import net.flashpunk.*;
    import net.flashpunk.utils.Input;
    import net.flashpunk.utils.Draw;

    public class Hud extends Sprite { 
        [Embed(source='/assets/buttons/pause.png')] private const PAUSE:Class;
        [Embed(source='/assets/buttons/play.png')] private const PLAY:Class;
        [Embed(source='/assets/buttons/two_ex.png')] private const TWO_EX:Class;
        [Embed(source='/assets/buttons/three_ex.png')] private const THREE_EX:Class;
        
        [Embed(source='/assets/sprites/goldcoin.png')] private const GOLDCOIN:Class;
        [Embed(source='/assets/hud/tutorial.png')] private const TUTORIAL:Class;
        
        [Embed(source='/assets/icons/music.png')] private const MUSIC:Class;
        [Embed(source='/assets/icons/mute_centered.png')] private const MUTE:Class;
        [Embed(source='/assets/icons/volume_high.png')] private const VOLUME:Class;

        public static const GRID_SPACING:int = 30;

        private var _modal_fade:Shape;
        
        private var _dialog_open:Boolean;
        private var _tooltips:Dictionary;
        private var _path_layer:PathLayer;
        
        private static var _instance:Hud;
        private static var _gametext:XML;
        private var _score_text:Text;
        private var _misc_text:Text;
        
        private var _status_panel:RoundedPanel;
        private var _speed_panel:RoundedPanel;
        private var _tut_panel:RoundedPanel;
        private var _menu_open:Boolean;
        private var _path_img:BitmapData;
        
        private var _query_window:QueryWindow;
        private var _messages:Object;
        private var _message_windows:Vector.<MessageWindow>;
        
        private var _end_screen:Interstitial;
        private var _path_panel:RoundedPanel;
        
        private var _restart_level:Signal;
        private var _next_level:Signal;
        
        public function Hud(p_key:SingletonBlocker):void {
            if (p_key == null) {
                throw new Error("Error: Instantiation failed: Use Hud.instance instead of new.");
            }

            _tooltips = new Dictionary(true);
            addEventListener(Event.ADDED_TO_STAGE, init);
            _message_windows = new Vector.<MessageWindow>();
            _restart_level = new Signal();
            _next_level = new Signal();
        }

        public function fadeIn():void {
            alpha = 0;
            visible = true;
            _status_panel.visible = _speed_panel.visible = true;
            new GTween(this, .5, {'alpha':1}, {'ease':Linear.easeNone});
        }
        
        public function fadeOut():void {
            new GTween(this, .5, {'alpha':0}, {'ease':Linear.easeNone, 'onComplete':function():void {
                visible = true;
            }});
        }

        public static function get instance():Hud {
            if (_instance == null) {
                _instance = new Hud(new SingletonBlocker());
            }
            return _instance;
        }

        public static function commafy(num:Number):String {
            var s:String = num.toString();
            return s.replace(/(.)(?=(.{3})+$)/g,"$1,");
        }

        public function addPathLayer():void {
            _path_layer = new PathLayer();
            _path_layer.messaging.add(showPathMessages);
            _path_img = new BitmapData(FP.width, FP.height, true, 0);
            _path_layer.addPoint(Main.level.start);
            addChild(_path_layer);
            addChildAt(_status_panel, numChildren-1);
        }
        
        public function showPathMessages(msg:int):void {
            switch(msg) {
                case PathLayer.POINT_TOO_CLOSE:
                    showMessage("Point too close to other waypoint.");
                    break;
                case PathLayer.POINT_NOT_VALID:
                    showMessage("That's not a valid waypoint.");
                    break;
            }
        }
        
        public function removePathLayer():void {
            var matrix:Array = [0.3086, 0.6094, 0.082, 0, 0, 0.3086, 0.6094, 0.082, 0, 0, 0.3086, 0.6094, 0.082, 0, 0, 0, 0, 0, .5, 0];
            _path_layer.filters = [new ColorMatrixFilter(matrix)];
            _path_img.draw(_path_layer);
            removeChild(_path_layer);
        }
        
        public function get score():Text { return _score_text; }

        public function get pathImage():BitmapData { return _path_img; }
        public function get pathLayer():PathLayer { return _path_layer; }
        public function get speedPanel():DisplayObject { return _speed_panel; }
        public function get restartLevel():Signal { return _restart_level; }
        public function get nextLevel():Signal { return _next_level; }

        private function init(evt:Event):void {
            removeEventListener(Event.ADDED_TO_STAGE, init);
            Fog.instance().visible = false;
            addChildAt(Fog.instance(), 0);

            var _score_panel:RoundedPanel = new RoundedPanel(this, 0, 0, 20);
            _score_panel.alpha = .85;
            var bmp:Bitmap = new GOLDCOIN();
            _score_panel.addChild(bmp);
            bmp.x = 5, bmp.y = 5;
            _score_text = new Text(_score_panel, 15, 0, Main.currentScore.toString());
            _score_panel.height = 20;
            _score_panel.x = 5, _score_panel.y = FP.height - 25;
            createToolTip(bmp, "Your Gold Reserves");
            createToolTip(_score_text, "Your Gold Reserves");
            
            _status_panel = new RoundedPanel(this, 0, 0, 0);
            _status_panel.alpha = 0;
                        
            _speed_panel = new RoundedPanel(_status_panel, 0, 0, 20);
            _speed_panel.alpha = .85;
            var pause_button:ToggleButton = _speed_panel.addChild(new ToggleButton(new PAUSE(), null, function():void { 
                FP.world.active = false;
                Main.changeRate(0);
                pause_button.toggled = true;
                play_button.toggled = three_ex_button.toggled = two_ex_button.toggled = false;
            })) as ToggleButton;
            pause_button.x = 10, pause_button.y = 4;
            createToolTip(pause_button, "Pause");
            
            var play_button:ToggleButton = _speed_panel.addChild(new ToggleButton(new PLAY(), null, function():void {
                if (FP.rate != 1.0 && FP.world.active) {
                    Main.changeRate(1.5);
                } else {
                    FP.world.active = true;
                    Main.changeRate(1.5);
                    pause_button.toggled = three_ex_button.toggled = two_ex_button.toggled = false;
                }
                play_button.toggled = true;
            })) as ToggleButton;
            play_button.toggled = true;
            play_button.x = pause_button.x + pause_button.width + 5, play_button.y = 4;
            createToolTip(play_button, "1x Speed");
            
            var two_ex_button:ToggleButton = _speed_panel.addChild(new ToggleButton(new TWO_EX(), null, function():void {
                if (!FP.world.active) FP.world.active = true;
                Main.changeRate(3.0);
                two_ex_button.toggled = true;
                play_button.toggled = three_ex_button.toggled = pause_button.toggled = false;
            })) as ToggleButton;
            two_ex_button.x = play_button.x + play_button.width+5, two_ex_button.y = 4;
            createToolTip(two_ex_button, "2x Speed");
            
            var three_ex_button:ToggleButton = _speed_panel.addChild(new ToggleButton(new THREE_EX(), null, function():void {
                if (!FP.world.active) FP.world.active = true;
                Main.changeRate(5.0);
                three_ex_button.toggled = true;
                play_button.toggled = pause_button.toggled = two_ex_button.toggled = false;
            })) as ToggleButton;
            three_ex_button.x = two_ex_button.x + two_ex_button.width + 5, three_ex_button.y = 4;
            createToolTip(three_ex_button, "3x Speed");
            
            var music:ToggleButton = _speed_panel.addChild(new ToggleButton(new MUSIC(), null, function():void {
                SoundBoard.muteGameTrack();
            })) as ToggleButton;
            music.toggled = true;
            music.x = three_ex_button.x + three_ex_button.width + 13, music.y = 2;
            createToolTip(music, "Music On/Off");
            
            var sound:ToggleButton = _speed_panel.addChild(new ToggleButton(new MUTE(), new VOLUME(), function():void {
                SoundBoard.mute();
            })) as ToggleButton;
            sound.toggled = true;
            sound.x = music.x + music.width + 3, sound.y = 2;
            createToolTip(sound, "Sound On/Off");
            
            Main.rateChanged.add(function(rate:Number):void {
                switch(rate) {
                    case 0:
                        pause_button.toggled = true;
                        play_button.toggled = three_ex_button.toggled = two_ex_button.toggled = false;
                        break;
                    case 1.5:
                        play_button.toggled = true;
                        pause_button.toggled = three_ex_button.toggled = two_ex_button.toggled = false;
                        break;
                    case 3.0:
                        two_ex_button.toggled = true;
                        play_button.toggled = three_ex_button.toggled = pause_button.toggled = false;
                        break;
                    case 5:
                        three_ex_button.toggled = true;
                        play_button.toggled = pause_button.toggled = two_ex_button.toggled = false;
                        break;
                }
            });
            
            _speed_panel.x = 635, _speed_panel.y = FP.height - 25;
            _speed_panel.height = 20;
            _misc_text = new Text(_speed_panel, 5, 0, "Help");
            _misc_text.buttonMode = true, _misc_text.useHandCursor = true;
            _misc_text.addEventListener(MouseEvent.CLICK, showHelp);
            _misc_text.selectable = _misc_text.editable = false;
            _misc_text.x = three_ex_button.x + three_ex_button.width + 55;
            _speed_panel.width = 230;
            drawMapGrid();
        }

        public function showHelp(evt:MouseEvent):void {
            trace("show help.");
            addEventListener(Event.ADDED, function(evt:Event):void {
                if (_tut_panel && contains(_tut_panel)) {
                    setChildIndex(_tut_panel, numChildren > 0 ? numChildren - 1 : numChildren);
                }
            });
            _misc_text.removeEventListener(MouseEvent.CLICK, showHelp);
            Main.changeRate(0);
            _tut_panel = new RoundedPanel(Hud.instance, 0, 0);
            var tut_img:Bitmap = new TUTORIAL();
            tut_img.x = 5, tut_img.y = 5;
            _tut_panel.addChild(tut_img);
            _tut_panel.width = tut_img.width + 10, _tut_panel.height = tut_img.height + 10;
            _tut_panel.x = FP.width/2 - _tut_panel.width/2, _tut_panel.y = FP.height/2 - _tut_panel.height/2;
            Reactor.callLater(function():void {
                 FP.stage.addEventListener(MouseEvent.CLICK, closeHelp);
            });
            Input.mouseReleased = false;
        }
        
        private function closeHelp(evt:MouseEvent):void {
            evt.stopPropagation();
            FP.stage.removeEventListener(MouseEvent.CLICK, closeHelp);
            removeChild(_tut_panel);
            Main.changeRate(1.5);
            _misc_text.addEventListener(MouseEvent.CLICK, showHelp);
        }

        private function createToolTip(obj:DisplayObject, title:String="", txt:String="", align:String="center"):void {
            var tt:ToolTip = new ToolTip();
            tt.delay = 500, tt.hookSize = 5;
            tt.titleEmbed = tt.contentEmbed = true;
            tt.titleFormat = tt.contentFormat = new TextFormat(Style.fontName, Style.fontSize, Style.LABEL_TEXT);
            tt.hook = true, tt.align = align;
            tt.colors = 0x000000, tt.bgAlpha = .5;
            tt.borderSize = 1, tt.border = 0xacacac;
            tt.minY = FP.screen.height - 30;
            if (txt == "") {
                tt.cornerRadius = 5, 
                tt.autoSize = true;
            } else {
                tt.cornerRadius = 10, 
                tt.tipWidth = int(obj.width * 2);
            }
            
            obj.addEventListener(MouseEvent.ROLL_OVER, function(evt:MouseEvent):void {
                tt.show(obj, title, txt);
            })
            _tooltips[obj] = tt;
        }

        public function drawMapGrid():void {
            graphics.lineStyle(1, 0xcccccc, .1);
            for (var i:int=GRID_SPACING; i < FP.screen.width; i+=GRID_SPACING) {
                graphics.moveTo(i, 0);
                graphics.lineTo(i, FP.screen.height);
            }
            for (i=GRID_SPACING; i < FP.screen.height; i+=GRID_SPACING) {
                graphics.moveTo(0, i);
                graphics.lineTo(FP.screen.width, i);
            }
        }

        public function clear(clear_msgs:Boolean=false):void {
            graphics.clear();
            if (clear_msgs) {
                for (var i:int=0; i < _message_windows.length; i++) {
                    if (contains(_message_windows[i])) removeChild(_message_windows[i]);
                }
            }
            _message_windows.length = 0;
            drawMapGrid();
        }

        public function modalFade():void {
            _dialog_open = true;
        }

        public function modalFadeClear():void {
            _dialog_open = false;
        }

        public function get dialogOpen():Boolean { return _dialog_open; }

        public function scoreText(e:Entity, score:int):void {
            var score_label:Text = new Text(this, e.x-10, e.y-30, "       +" + commafy(score));
            score_label.scaleX = score_label.scaleY = 0;
            score_label.width = 75, score_label.height = 20;
            score_label.x = e.x+20, score_label.y = e.y - score_label.height/2;
            var tf:TextField = score_label.textField;
            var tff:TextFormat = tf.getTextFormat();
            tff.align = "center";
            tf.setTextFormat(tff);
            tf.x -= tf.width/2, tf.y -= tf.height/2;
            new GTween(score_label, .5, {'scaleX': 1, 'scaleY':1, 'y':e.y-30}, {'ease':Linear.easeNone, 'onComplete': function():void {
                new GTween(score_label, 2.0, {'alpha':0}, {'ease':Linear.easeNone, 'onComplete':function():void {
                    removeChild(score_label);
                    score_label = null;
                }})
            }});
        }

        public function showCommandResponse(x:int, y:int, s:String):CommandLabel {
            var response_label:CommandLabel = new CommandLabel(this, 0, 0, s);
            response_label.x = x
            response_label.y = y;
            new GTween(response_label, 2.5, {'alpha': 0}, {'ease':Linear.easeNone, 'onComplete': function():void {
                removeChild(response_label);
                response_label = null;
            }});
            return response_label;
        } 

        public function removeMessage(msg:MessageWindow):void {
            _message_windows.splice(_message_windows.indexOf(msg), 1);
            if (contains(msg)) removeChild(msg);
        }
    
        private function sortMessages(a:MessageWindow, b:MessageWindow):int {
            if (a.priority > b.priority) return 1;
            if (a.priority == b.priority) {
                if (a.timeAdded > b.timeAdded) return -1;
                if (a.timeAdded < b.timeAdded) return 1;
                if (a.timeAdded == b.timeAdded) return 0;
            }
            if (a.priority < b.priority) return -1;
            return 0;
        }
    
        public function showMessage(message:String, msg_len:int=7, priority:int=1):void {
            var _message_window:MessageWindow = new MessageWindow(this, 0, 15, priority);
            _message_window.visible = false;
            var idx:int = _message_windows.length;
            _message_window.message = message;
            _message_window.x = FP.width/2 - _message_window.width/2;
            _message_window.width += 20, _message_window.height += 10;
            _message_windows.push(_message_window);
            _message_windows = _message_windows.sort(sortMessages);
            for (var i:int=0, j:int=1; i < _message_windows.length; i++,j+=9) {
                var target:int = j * 6;
                if (i == 1) {
                    new GTween(_message_windows[i], .5, {'y': target}, {'ease':Linear.easeNone, 'onComplete':function():void {
                        _message_window.visible = true;
                    }});
                } else {
                    new GTween(_message_windows[i], .5, {'y': target}, {'ease':Linear.easeNone});
                }
            }
            if (_message_windows.length == 1) { _message_window.visible = true; }
            new GTween(_message_window, msg_len, {}, {'ease':Linear.easeNone, 'onComplete': function():void {
                new GTween(_message_window, .5, {'alpha': 0}, {'ease':Linear.easeNone, 'onComplete': function():void {
                    if (contains(_message_window)) removeChild(_message_window);
                    _message_windows.splice(_message_windows.indexOf(_message_window), 1);
                }});
            }});
        }
        
        public function showPathConfirmDialog(confirmFun:Function, clearFun:Function):void {
            modalFade();
            if (_path_panel && contains(_path_panel)) {
                removeChild(_path_panel);
                _path_panel = null;
            }
            _path_panel = new RoundedPanel(this, 0, 0, 20);
            _path_panel.alpha = .85, _path_panel.visible = false;
            var txt:Label = new Label(_path_panel, 10, 10, "Use this path and launch your fleet?");
            _path_panel.color = 0;
            _path_panel.width = 350;
            _path_panel.height = 75;
            txt.width = 280;
            txt.height = 25;
            _path_panel.x = (FP.width/2)-(_path_panel.width/2);
            _path_panel.y = (FP.height/2)-(_path_panel.height/2);
            var clearButton:PushButton = new PushButton(_path_panel, 190, 40, "No, Not yet", function(evt:MouseEvent):void {
                clearButton.enabled = false;
                modalFadeClear();
                if (clearFun != null) clearFun();
                removeChild(_path_panel);
                _path_panel = null;
                Input.mouseReleased = false;
                showMessage("To finish your path, just create a waypoint to the extraction zone again.");
            });
            var okButton:PushButton = new PushButton(_path_panel, 80, 40, "Ok, I'm ready", function(evt:MouseEvent):void {
                okButton.enabled = false;
                modalFadeClear();
                if (confirmFun != null) confirmFun();
                removeChild(_path_panel);
                _path_panel = null;
                Input.mouseReleased = false;
            });
            _path_panel.draw();
            Reactor.callLater(function():void {
                _path_panel.visible = true;
            });
        }
        
        public function showLevelComplete(status:Boolean):void {
            clear(true);
            Main.changeRate(0);
            _status_panel.visible = _speed_panel.visible = false;
            SoundBoard.muteGameTrack(function():void {
                SoundBoard.playEffect(status ? "victory" : "defeat");
            })
            _end_screen = new Interstitial(status);
            _end_screen.x = -_end_screen.height
            addChild(_end_screen);
            new GTween(_end_screen, .5, {'y':0}, {'ease':Linear.easeNone});
        }
        
        public function removeLevelComplete():void {
            if (contains(_end_screen)) removeChild(_end_screen);
        }
    }
}

internal class SingletonBlocker {}