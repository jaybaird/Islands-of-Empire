package world.entities {
    import net.flashpunk.*;
    import net.flashpunk.graphics.Emitter;
    import net.flashpunk.tweens.misc.Alarm;
    
    import lib.swfstats.*;
    import org.osflash.signals.Signal;
    
    import util.*;
    import world.*;
    import effects.*;
    import net.flashpunk.*;
    
    public class Damageable extends Entity {
        protected var _targetable:Boolean;
        protected var _health:Number;
        protected var _emitter:Emitter;
        protected var _fire_emitter:Emitter;
        protected var _explosion_emitter:Emitter;
        protected var _blowing_up:Boolean;
        protected var _damage:Alarm;
        protected var _remove_entity:Signal;
        
        public function Damageable(x:int=0, y:int=0, img:Graphic=null):void {
            super(x, y, img);
            _remove_entity = new Signal(Entity);
        }
        
        override public function added():void {
            super.added();
            _targetable = true;
            _emitter = (FP.world.classFirst(Smoke) as Smoke).emitter;
            _explosion_emitter = (FP.world.classFirst(Explosion) as Explosion).emitter;
        }
        
        override public function removed():void {
            _targetable = false;
        }
        
        public function get blewUp():Signal {
            return _remove_entity;
        }
        
        public function get targetable():Boolean { return _targetable; }
        public function set targetable(value:Boolean):void {
            _targetable = value;
        }
        
        override public function set visible(value:Boolean):void {
            super.visible = value;
            if (_damage && hasTween(_damage) && !value) {
                removeTween(_damage);
            }
        }
        
        public function reset():void {
            if (_damage) {
                removeTween(_damage);
                _damage = null;
            }
            _damage = null;
            _health = 100;
            _targetable = true;
            _blowing_up = false;
        }
        
        public function get health():int { return _health; }
        public function set health(value:int):void {
            if (this is Ship && value < 100 && (FP.world as Map).shipDamaged != null) {
                (FP.world as Map).shipDamaged.dispatch(this);
            }
            _health = (value < 0) ? 0 : value;
            if (_health == 0 && !_blowing_up) {
                _blowing_up = true;
                _explosion_emitter.emit("explosion", x, y);
                if (this is Fort) {
                    SoundBoard.playEffect("fortExplosion");
                } else if (this is Ship) {
                    SoundBoard.playEffect("shipExplosion");
                }
                _remove_entity.dispatch(this);
                return;
            }
            if (_health <= 70) {
                if (!_damage) {
                    _damage = new Alarm(_health/100, showDamage, Tween.LOOPING);
                    addTween(_damage, true);
                } else {
                    _damage.reset(_health/100);
                } 
            } 
            healthUpdated();
        }
        
        private function showDamage():void {
            _emitter.emit("smoke", x - 10 + FP.rand(20), y - 10 + FP.rand(20));
        }
        
        protected function healthUpdated():void {}
    }
}