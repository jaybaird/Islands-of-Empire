package world.entities {
    import flash.utils.*;
    import flash.text.*;
    import flash.geom.*;
    import flash.events.*;
    import flash.display.*;
    import flash.filters.*;
    
    import net.flashpunk.*;
    import net.flashpunk.graphics.*;
    import net.flashpunk.masks.Pixelmask;
    import net.flashpunk.utils.*;
    import net.flashpunk.tweens.misc.Alarm;
    
    import com.bit101.components.Style;
    import org.osflash.signals.Signal;
    
    import gfx.*;
    import effects.*;
    import util.*;
    import util.ds.Vector2D;
    import components.*;
    import ai.*;
    import ai.data.Blackboard;
    import world.Map;
   
    public class Ship extends Damageable {
        public static var TOTAL_HEALTH:int;
        public static var WIDTH:int;
        public static var PATH_THRESHOLD:int;
        {
            TOTAL_HEALTH = 360;
            WIDTH = 24;
            PATH_THRESHOLD = 5;
        }
        
        public var arrived:Signal;
        public var atPoint:Signal;
        
        // SHIP POSITION VARIABLES
        public var velocity:Vector2D;
        public var position:Vector2D;
        public var moving_velocity:Vector2D;
        protected var _steering_force:Vector2D;
        protected var _mass:Number;
        protected var _max_speed:Number;
        protected var _max_force:Number;
        protected var _moving:Boolean;
        protected var _path:Vector.<Point>;
        protected var _path_index:int;
        
        protected var _cannon_emitter:Emitter;
        protected var _hud:ShipHud;
        protected var _shape:Sprite;
        protected var _tooltip:ToolTip;

        protected var _current_target:Damageable;
        protected var _cooling_off:Boolean;
        protected var _fleeing:Boolean;
        protected var _removed:Boolean;
        protected var _fired:Signal;
        protected var _sight_range:int;
        protected var _flee_distance:int;
        protected var _command_label:CommandLabel;
        
        protected var _selected:Boolean;
        protected var _spritemaps:Vector.<Spritemap>;
        
        protected var _fog_mask:Bitmap;
        protected var _rate_of_fire:Alarm;
        protected var _requested_target:Damageable;
        
        protected var _hit_rate:Number;
        protected var _kills:int;
        protected var _hits:int;
        protected var _shots_fired:int;
        
        protected var _name:String;
        
        public var targets:Array;
        
        public var range:int;
        public var rateOfFire:int;
        
        [Embed(source="/assets/sprites/bigship_frames.png")] public static const PLAYER_SHIP:Class;
        [Embed(source="/assets/sprites/bigship_frames_damage_2.png")] public static const PLAYER_SHIP_DAMAGE2:Class;
        [Embed(source="/assets/sprites/bigship_frames_damage_3.png")] public static const PLAYER_SHIP_DAMAGE3:Class;
        [Embed(source="/assets/sprites/bigship_frames_damage_4.png")] public static const PLAYER_SHIP_DAMAGE4:Class;
        
        public function Ship(name:String):void {
            super();
            _name = name;
            setHitbox(WIDTH, WIDTH, 12, 24);
            arrived = new Signal(Ship);
            atPoint = new Signal(Ship, int);
            _fired = new Signal();
            type = "ship";
            _hud = new ShipHud(this);
            _hud.visible = false;
            _path_index = -1;
            _moving = false;
            _sight_range = 64;
            _flee_distance = 150;
            _rate_of_fire = new Alarm(rateOfFire, function():void {
                                _cooling_off = false;
                            }, Tween.PERSIST);
            addTween(_rate_of_fire, false);
            rateOfFire = 2.5;
            range = 50;
            targets = ['enemyship', 'fort'];
            createSpritemaps();
            graphic = _spritemaps[0];
            health = TOTAL_HEALTH;
            createFogMask();
        }
        
        protected function createFogMask():void {
            var circle:Shape = new Shape();
            with(circle.graphics) {
                beginFill(0xffffff, 1);
                drawEllipse(0, 0, _sight_range*2, _sight_range*2);
            }
            circle.filters = [new GlowFilter(0, 1, _sight_range, _sight_range, 4, BitmapFilterQuality.LOW, false, false)];
            _fog_mask = new Bitmap(new BitmapData(_sight_range*2+100, _sight_range*2+100, true, 0));
            _fog_mask.bitmapData.draw(circle, new Matrix(1, 0, 0, 1, 50, 50));
            _fog_mask.blendMode = BlendMode.LAYER;
        }
        
        protected function createSpritemaps():void {
            _spritemaps = new Vector.<Spritemap>();
            var sprites:Vector.<Class> = Vector.<Class>([PLAYER_SHIP, PLAYER_SHIP_DAMAGE2, PLAYER_SHIP_DAMAGE3, PLAYER_SHIP_DAMAGE4]);
            var i:int = sprites.length;
            while(--i > -1) {
                var sprite:Spritemap = new Spritemap(sprites[i], 24, 24);
                sprite.smooth = false;
                sprite.add("main", [0, 1, 2, 3], 1);
                sprite.play("main");
                sprite.x = -12;
                sprite.y = -24;
                _spritemaps.unshift(sprite);
            }
        }

        override public function added():void {
            super.added();
            if (FP.getClass(this) != EnemyShip) { createToolTip(); }
            position = new Vector2D(x, y);
            velocity = new Vector2D();
            moving_velocity = new Vector2D();
            _steering_force = new Vector2D();
            _max_force = 40;
            _mass = 2.5;
            _max_speed = (Main.upgrades.sails && FP.getClass(this) != EnemyShip) ? 85 : 65;
            _cannon_emitter = (FP.world.classFirst(CannonSmoke) as CannonSmoke).emitter;
            _removed = false;
            active = true;
        }
        
        override public function removed():void {
            _removed = true;
            if (_command_label) _command_label = null;
            super.removed();
        }
        
        public function get point():Point { return new Point(x, y); }
        
        override protected function healthUpdated():void {
            if (_health < 135 && _health >= 90) {
                graphic = _spritemaps[1];
            } else if (_health < 90 && _health >= 45) {
                graphic = _spritemaps[2];
            } else if (_health < 45) {
                graphic = _spritemaps[3];
            } else {
                graphic = _spritemaps[0];
            }
            _hud.update(_health);
        }
        
        override public function render():void {
            if (_hud.visible) {
                _hud.render();
            }
            //Draw.hitbox(this);
            super.render();
        }
        
        public function set totalHealth(value:Number):void { TOTAL_HEALTH = value; }
        public function set maxSpeed(value:Number):void { _max_speed = value; }
        public function get name():String { return _name; }
        public function get pathIndex():int { return _path_index; }
        public function get fired():Signal { return _fired; }
        
        public function get sightDistance():int { return _sight_range; }
        public function set sightDistance(value:int):void {
            _sight_range = value;
            createFogMask();
        }
        public function get fogMask():Bitmap { return _fog_mask; }
        
        public function get selected():Boolean { return _selected; }
        public function set selected(value:Boolean):void {
            _hud.visible = _selected = value;
        }
        
        public function moveTo(path:Vector.<Point>):void {
            if (path) { 
                _path_index = 0;
                _path = path;
            }
        }
        
        protected function arrive(target:Vector2D):void {
            var desired_velocity:Vector2D = target.subtract(position);
            desired_velocity.normalize();
            var dist:Number = position.dist(target);
            if (dist > PATH_THRESHOLD) {
                desired_velocity = desired_velocity.multiply(_max_speed);
            } else {
                desired_velocity = desired_velocity.multiply(_max_speed * (dist/PATH_THRESHOLD));
            }
            var force:Vector2D = desired_velocity.subtract(velocity);
            _steering_force = _steering_force.add(force);
        }
        
        public function pause():void {
            velocity = new Vector2D(0, 0);
            _steering_force = new Vector2D(0, 0);
        }
        
        public function stop():void {
            velocity = new Vector2D(0, 0);
            _steering_force = new Vector2D(0, 0);
            _path_index = -1;
            if (_path) _path.length = 0;
        }
        
        private function followPath():void {
            if (_path_index < 0 || _path_index >= _path.length) {
                return;
            }
            var map_node:Point = _path[_path_index];
            var current_waypoint:Vector2D = new Vector2D(map_node.x, map_node.y);
            _moving = true;
            if (position.dist(current_waypoint) < PATH_THRESHOLD) {
                if(_path_index >= _path.length - 1) {
                    arrived.dispatch(this);
                    _moving = false;
                } else {
                    _path_index++;
                    atPoint.dispatch(this, _path_index);
                }
            } else {
                var flip:Boolean;
                if (current_waypoint.x < position.x) {
                    (graphic as Spritemap).flipped = true;
                } else if (current_waypoint.x > position.x) {
                    (graphic as Spritemap).flipped = false;
                }
            }
            if (_path_index >= _path.length - 1) {
                arrive(current_waypoint);
            } else {
                seek(current_waypoint);
            }
        }
        
        protected function seek(target:Vector2D):void {
            var desired_velocity:Vector2D = target.subtract(position);
            desired_velocity.normalize();
            desired_velocity = desired_velocity.multiply(_max_speed);
            var force:Vector2D = desired_velocity.subtract(velocity);
            _steering_force = _steering_force.add(force);
        }
        
        protected function moveShip():void {
            if (_path) followPath();
            _steering_force.truncate(_max_force);
            _steering_force = _steering_force.divide(_mass);
            velocity = velocity.add(_steering_force);
            _steering_force = new Vector2D();
            velocity.truncate(_max_speed);
            moving_velocity.x = velocity.x;
            moving_velocity.y = velocity.y;
            velocity.x = velocity.x * FP.elapsed;
            velocity.y = velocity.y * FP.elapsed;
            position = position.add(velocity);
            
            x = position.x;
            y = position.y;
        }
        
        private function createToolTip():void {
            _shape = new Sprite();
            _shape.graphics.beginFill(0, 0);
            _shape.graphics.drawRect(0, 0, 32, 32);
            FP.stage.addChild(_shape);
            _tooltip = new ToolTip();
            _tooltip.delay = 250, _tooltip.hookSize = 5;
            _tooltip.titleEmbed = _tooltip.contentEmbed = true;
            _tooltip.titleFormat = _tooltip.contentFormat = new TextFormat(Style.fontName, Style.fontSize, Style.LABEL_TEXT);
            _tooltip.hook = true, _tooltip.align = "center";
            _tooltip.colors = 0x000000, _tooltip.bgAlpha = 1;
            _tooltip.borderSize = 1, _tooltip.border = 0xacacac;
            _tooltip.cornerRadius = 10, _tooltip.minY = 0;
            _tooltip.autoSize = true;
            _tooltip.tipWidth = 200;
            _shape.addEventListener(MouseEvent.ROLL_OVER, function(evt:MouseEvent):void {
                _tooltip.show(_shape, name, getStats());
            })
        }
        
        public function showStats(p:DisplayObject):void {
            if (_tooltip == null) createToolTip();
            _tooltip.show(p, name, getStats());
        }

        protected function getStats():String {
            return "\nHP: " + health + "/" + FP.getClass(this).TOTAL_HEALTH + "\nKills: " + _kills + "    Hit %: " + int(_hit_rate * 100) + "%\nHits: " + _hits + "    Shots Fired: " + _shots_fired;
        }
        
        protected function checkInput():void {
            FP.point.x = FP.world.mouseX, FP.point.y = FP.world.mouseY;
            if (collidePoint(x, y, FP.point.x, FP.point.y)) {
                _hud.visible = true;
            } else {
                _hud.visible = false;
            }
        }
                
        public function setTarget(e:Entity):void {
            if (e is Damageable) {
                _requested_target = (e as Damageable);
            }
        }
        
        public function set hits(value:int):void { _hits = value; }
        public function get hits():int { return _hits; }
        
        public function set kills(value:int):void { _kills = value; }
        public function get kills():int { return _kills; }
        
        public function set shotsFired(value:int):void { _shots_fired = value; }
        public function get shotsFired():int { return _shots_fired; }
        
        public function get hitRate():int { return _hit_rate; }
        
        private function getAccuracy():Number {
            if (Main.upgrades.cannon) return 0.98;
            if (Main.level.number < 3) return 0.8;
            if (Main.level.number >= 6 && Main.level.number < 9) return 0.85;
            if (Main.level.number >= 9 && Main.level.number < 12) return 0.90;
            if (Main.level.number == 12) return 0.95;
            return 0.8;
        }
        
        protected function attack():void {
            if (_cooling_off) return;
            if (_current_target && !_current_target.targetable) _current_target = null;
            if (_requested_target && distanceFrom(_requested_target, true) <= range) {
                    _current_target = _requested_target;
                    _requested_target = null;
            }
            if (_current_target) {
                if (distanceFrom(_current_target, true) > range) {
                    //trace("[SHIP] target has moved out of range");
                    _current_target = null;
                } else {
                    //trace("[SHIP] firing!");
                    var cannon_smoke:CannonSmoke = (FP.world.classFirst(CannonSmoke) as CannonSmoke);
                    var cannonball:Cannonball = FP.world.create(Cannonball, true) as Cannonball;
                    cannonball.x = this.x, cannonball.y = this.y;
                    cannonball.accuracy = getAccuracy();
                    if (FP.getClass(this) is Airship) {
                        cannonball.damage = 15;
                    } else if (Main.upgrades.cannon) {
                        cannonball.damage = 20;
                    } else {
                        cannonball.damage = 10;
                    }
                    if (FP.getClass(_current_target) is EnemyShip && Main.upgrades.grapeShot) {
                        // grape shot upgrades damage against enemy ships
                        cannonball.damage += cannonball.damage * (Main.random(.3, .1));
                    }
                    cannonball.target(_current_target);
                    cannonball.shooter = this;
                    cannonball.fire();
                    shotsFired += 1;
                    cannonball.targetHit.add(function():void {
                        hits += 1;
                        _hit_rate = _hits / _shots_fired;
                    });
                    cannon_smoke.layer = (_current_target.y > y) ? layer - 10 : layer + 10;
                    _fired.dispatch();
                    _cannon_emitter.emit("cannon_smoke", this.x+6, this.y+5);
                    _cooling_off = true;
                    //trace("[SHIP] reloading");
                    _rate_of_fire.reset(rateOfFire);
                }
            } else {
                for (var i:int=0; i < targets.length; i++) {
                    var e:Entity = FP.world.nearestToEntity(targets[i], this, true);
                    if (e && distanceFrom(e, true) < range) {
                        //trace("[SHIP] got a target");
                        _current_target = e as Damageable;
                        break;
                    }
                }
            }
        }
        
        override public function update():void {
            moveShip();
            checkInput();
            attack();
            _shape.x = position.x - 16, _shape.y = position.y - 32;
            _tooltip.setContent(name, getStats());
            try {
                layer = -y;
            } catch(e:Error) {}
            if (x >= FP.screen.width + WIDTH) {
                active = false;
                visible = false;
                FP.world.remove(this);
            }
        }
    }
}