package world.entities {
    import flash.display.*;
    
    import net.flashpunk.*;
    import net.flashpunk.graphics.*;
    import net.flashpunk.tweens.misc.Alarm;
    
    import gfx.*;
    import effects.*;
    
    public class Fort extends Damageable {
        [Embed(source='/assets/sprites/fort.png')] private const FORT:Class;
        [Embed(source='/assets/sprites/fort_damage_2.png')] private const FORT_DAMAGE1:Class;
        [Embed(source='/assets/sprites/fort_damage_3.png')] private const FORT_DAMAGE2:Class;
        [Embed(source='/assets/sprites/fort_damage_4.png')] private const FORT_DAMAGE3:Class;
        
        public static const WIDTH:int = 16;
        public static const TOTAL_HEALTH:int = 100;
        
        private var _spritemaps:Vector.<Stamp>;
        private var _current_target:Ship;
        private var _cooling_off:Boolean;
        private var _cannon_emitter:Emitter;
        private var _destroyed:Boolean;
        private var _rate_of_fire:Alarm;
        protected var _hud:ShipHud;
        
        public var rateOfFire:int;
        public var range:int;
        
        public function Fort(x:int, y:int):void {
            super(x, y);
            _hud = new ShipHud(this);
            type = "fort";
            range = 60;
            health = 100;
            visible = false;
            rateOfFire = 2.0;
            createSpritemaps();
            graphic = _spritemaps[0];
            setHitbox(WIDTH, WIDTH, 8, 16);
            _rate_of_fire = new Alarm(rateOfFire, function():void {
                                _cooling_off = false;
                            }, Tween.PERSIST);
            addTween(_rate_of_fire, false);
        }
        
        protected function createSpritemaps():void {
            _spritemaps = new Vector.<Stamp>();
            var sprites:Vector.<Class> = Vector.<Class>([FORT, FORT_DAMAGE1, FORT_DAMAGE2, FORT_DAMAGE3]);
            var i:int = sprites.length;
            while( --i > -1 ) {
                var sprite:Stamp = new Stamp(sprites[i]);
                sprite.x = -8;
                sprite.y = -16;
                _spritemaps.unshift(sprite);
            }
        }
        
        public function get destroyed():Boolean { return _destroyed; }
        public function set destroyed(value:Boolean):void {
            _destroyed = value;
        }
        
        override protected function healthUpdated():void {
            if (_health < 90 && _health >= 70) {
                graphic = _spritemaps[1];
            } else if (_health < 70 && _health >= 40) {
                graphic = _spritemaps[2];
            } else if (_health < 40) {
                graphic = _spritemaps[3];
            }
             _hud.update(_health);
        }
        
        private function getAccuracy():Number {
            if (Main.level.number < 3) return 0.8;
            if (Main.level.number >= 6 && Main.level.number < 9) return 0.85;
            if (Main.level.number >= 9 && Main.level.number < 12) return 0.90;
            if (Main.level.number == 12) return 0.95;
            return 0.8;
        }
        
        private function attack():void {
            if (_cooling_off) return;
            if (_current_target && !_current_target.targetable) _current_target = null;
            if (_current_target) {
                if (distanceFrom(_current_target, true) > range) {
                    //trace("[FORT] target has moved out of range");
                    _current_target = null;
                } else {
                    //trace("[FORT] firing!");
                    var cannonball:Cannonball = FP.world.create(Cannonball, true) as Cannonball;
                    cannonball.x = this.x, cannonball.y = this.y-5;
                    cannonball.damage = 10;
                    cannonball.accuracy = getAccuracy();
                    cannonball.target(_current_target, true);  // since ships are moving targets we need to lead ships
                    cannonball.shooter = this;
                    cannonball.fire();
                    _cannon_emitter.emit("cannon_smoke", this.x+6, this.y+5);
                    _cooling_off = true;
                    //trace("[FORT] reloading");
                    _rate_of_fire.reset(rateOfFire);
                }
            } else {
                var e:Entity = FP.world.nearestToEntity("ship", this, true);
                if (e && distanceFrom(e, true) < range) {
                    //trace("[FORT] got a target");
                    _current_target = e as Ship;
                }
            }
        }
        
        override public function render():void {
            if (_hud.visible) {
                _hud.render();
            }
            super.render();
        }
        
        override public function added():void {
            super.added();
            _cannon_emitter = (FP.world.classFirst(CannonSmoke) as CannonSmoke).emitter;
        }
        
        private function checkInput():void {
            FP.point.x = FP.world.mouseX, FP.point.y = FP.world.mouseY;
            if (collidePoint(x, y, FP.point.x, FP.point.y)) {
                _hud.visible = true;
            } else {
                _hud.visible = false;
            }
        }
        
        override public function update():void {
            attack();
            checkInput();
        }
    }
}