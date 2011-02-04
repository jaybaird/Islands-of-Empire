package world.entities {
    import flash.geom.Point;
    
    import net.flashpunk.*;
    import net.flashpunk.graphics.*;
    import net.flashpunk.tweens.motion.*;
    
    import org.osflash.signals.Signal;
    
    import util.*;
    import effects.*;
    
    public class Cannonball extends Entity {
        private static const OFFSET:Number = 1.0/3.0;
        [Embed(source='/assets/sprites/cannonball.png')] private static const CANNONBALL:Class;
        [Embed(source='/assets/sprites/cannonball_shadow.png')] private static const CANNONBALL_SHADOW:Class;
        
        private var _update:Boolean;
        private var _start:Point;
        private var _end:Point;
        private var _length:Number;
        private var _target:Damageable;
        private var _t:Number;
        private var _apex:Point;
        private var _leading:Boolean;
        private var _shooter:Entity;
        private var _splash_emitter:Emitter;
        
        private var _shadow_entity:Entity;
        private var _missed:Boolean;
        
        private var _target_hit:Signal;
        private var _curved_motion:QuadMotion;
        private var _shadow_motion:LinearMotion;
        
        public var accuracy:Number = 1.0;
        public var velocity:int = 40;
        public var damage:int = 10;

        public function Cannonball(x:int=0, y:int=0):void {  
            var img:Stamp = new Stamp(CANNONBALL);
            img.x = -2, img.y = -2;
            type = "cannonball";
            super(x, y, img); 
            setHitbox(img.source.width, img.source.height, 2, 2);
            var shadow_img:Stamp = new Stamp(CANNONBALL_SHADOW);
            shadow_img.x = shadow_img.y = -4;
            _shadow_entity = new Entity(x, y, shadow_img);
            _shadow_entity.collidable = false;
            
            _target_hit = new Signal(/*XXX: Entity that fired shot*/);
            _curved_motion = new QuadMotion(hitTarget);
            _shadow_motion = new LinearMotion();
            addTween(_curved_motion, false);
            addTween(_shadow_motion, false);
        }
        
        override public function added():void {
            _splash_emitter = (FP.world.classFirst(Splash) as Splash).emitter;
            FP.world.add(_shadow_entity);
        }
        
        override public function removed():void {
            FP.world.remove(_shadow_entity);
        }
        
        private function findApex(p:Point, h:Number):Point {
            var perpScaled:Point = perp(_start.subtract(_end));
            perpScaled.normalize(h);
            return (p.x <= _start.x) ? p.add(perpScaled) : p.subtract(perpScaled);
        }

        private function perp(p:Point):Point {
            return new Point(p.y, -p.x);
        }
        
        public function get targetHit():Signal { return _target_hit; }
        
        public function set shooter(value:Damageable):void {
            _shooter = value;
            if (value.y > y) {
                layer = value.layer - 1;
            }
        }
        
        public function target(value:Damageable, lead:Boolean=false):void {
            _missed = false;
            _target = value;
            _start = new Point(x, y);
            if (lead) {
                var ship:Ship = _target as Ship;
                var target:Point = new Point(ship.x - _start.x, ship.y - _start.y);
                var a:Number = velocity * velocity - (ship.moving_velocity.x * ship.moving_velocity.x + ship.moving_velocity.y * ship.moving_velocity.y);
                var b:Number = target.x * ship.moving_velocity.x + target.y * ship.moving_velocity.y;
                var c:Number = target.x * target.x + target.y * target.y;
                var d:Number = b*b + a*c;
                var t:Number = 0;
                if (d >= 0) {
                    t = (b + Math.sqrt(d)) / a;
                    if (t < 0) t = 0;
                }
                _end = new Point(ship.x + ship.moving_velocity.x * (t), ship.y + ship.moving_velocity.y * (t));
            } else {
                _end = new Point(value.x, value.y-6);
            }
            if (Math.random() > accuracy) {
                _missed = true;
                if (Math.random() > 0.5) {
                    _end.x += (Math.random() > 0.5) ? -_target.width : _target.width;
                } else {
                    _end.y += (Math.random() > 0.5) ? -_target.height : _target.height;
                }
                
            }
            _length = Point.distance( _start, _end );
            _apex = findApex(Point.interpolate(_end, _start, 0.5), _length * 0.5);
        } 
        
        public function fire():void {
            _t = 0;
            _update = true;
            SoundBoard.playEffect("cannon");
            _curved_motion.setMotion(x, y, _apex.x, _apex.y, _end.x, _end.y, _length/velocity);
            _shadow_motion.setMotion(x, y, _end.x, _end.y, _length/velocity);
        }
        
        private function hitTarget():void {
            _update = false;
            if (collideWith(_target, x, y)) {
                _target.blewUp.add(checkDeath);
                _target.health = _target.health - damage;
                _target.blewUp.remove(checkDeath);
                _target_hit.dispatch();
            } else if (!collide("island", x, y)) {
                _splash_emitter.emit("splash", x, y);
            }
            _target_hit.removeAll();
            FP.world.recycle(this);
            return;
        }
        
        private function checkDeath(e:Entity):void {
            if (_shooter && _shooter is Ship) {
                (_shooter as Ship).kills += 1;
            }
        }
        
        override public function update():void {
            if (!_update) return;
            x = _curved_motion.x, y = _curved_motion.y;
            _shadow_entity.x = _shadow_motion.x, _shadow_entity.y = _shadow_motion.y;
        }
    }
}