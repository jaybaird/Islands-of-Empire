package world.entities {
    import flash.geom.Point;
    import flash.events.Event;
    
    import net.flashpunk.*;
    import net.flashpunk.graphics.*;
    import net.flashpunk.masks.Pixelmask;
    import net.flashpunk.utils.*;
    import net.flashpunk.tweens.misc.Alarm;
    
    import org.osflash.signals.Signal;
    
    import gfx.*;
    import effects.*;
    import util.*;
    import components.*;
    import ai.*;
    import ai.data.Blackboard;
    import world.Map;
    
    import util.fsm.*;
    import ai.states.*;
    
    public class EnemyShip extends Ship {
        [Embed(source="/assets/sprites/bigship_red_frames.png")] public static const SHIP:Class;
        [Embed(source="/assets/sprites/bigship_red_frames_damage_2.png")] public static const SHIP_DAMAGE2:Class;
        [Embed(source="/assets/sprites/bigship_red_frames_damage_3.png")] public static const SHIP_DAMAGE3:Class;
        [Embed(source="/assets/sprites/bigship_red_frames_damage_4.png")] public static const SHIP_DAMAGE4:Class;
        
        public static var TOTAL_HEALTH:int;
        public static var WIDTH:int;
        public static var PATH_THRESHOLD:int;
        {
            TOTAL_HEALTH = 180;
            WIDTH = 24;
            PATH_THRESHOLD = 5;
        }
        
        public var fsm:StateMachine;
        private var _map:Map;
        private var _state_set:Boolean;
        private var _hard_visible:Boolean;
        
        public function EnemyShip(m:Map):void {
            super('enemy_ship');
            createSpritemaps();
            graphic = _spritemaps[0];
            type = 'enemyship';
            targets = ['ship'];
            health = TOTAL_HEALTH;
            _path = null;
            _map = m;
            active = false;
            fsm = new StateMachine();
        }
        
        override protected function createSpritemaps():void {
            _spritemaps = new Vector.<Spritemap>();
            var sprites:Vector.<Class> = Vector.<Class>([SHIP, SHIP_DAMAGE2, SHIP_DAMAGE3, SHIP_DAMAGE4]);
            for (var i:int=0; i < sprites.length; i++) {
                var sprite:Spritemap = new Spritemap(sprites[i], 24, 24);
                sprite.smooth = false;
                sprite.add("main", [0, 1, 2, 3], 1);
                sprite.play("main");
                sprite.x = -12;
                sprite.y = -24;
                _spritemaps.push(sprite);
            }
        }
        
        public function set hard_visible(value:Boolean):void { _hard_visible = visible = value; }
        public function get hard_visible():Boolean { return _hard_visible; }
        
        public function get map():Map { return _map; }
        
        override public function added():void {
            super.added();
            _max_speed = 75;            
            visible = false;
            if (!_state_set) fsm.changeState(new Patrol(this));
        }
        
        public function setState(state:String, ... args):void {
            _state_set = true;
            trace("Switching to ", state);
            switch(state) {
                case "seek":
                    fsm.changeState(new Seek(this, args[0] as Point, args[1] as int));
                break;
                case "patrol":
                    fsm.changeState(new Patrol(this));
                break;
                case "attack":
                    fsm.changeState(new Attack(this));
                break;
                case "hold":
                    fsm.changeState(new Hold(this));
                break;
            }
        }
        
        private function getAccuracy():Number {
            if (Main.level.number < 3) return 0.8;
            if (Main.level.number >= 6 && Main.level.number < 9) return 0.85;
            if (Main.level.number >= 9 && Main.level.number < 12) return 0.90;
            if (Main.level.number == 12) return 0.95;
            return 0.8;
        }
        
        override protected function attack():void {
            if (_cooling_off) return;
            if (_current_target && !_current_target.targetable) _current_target = null;
            if (_current_target) {
                if (distanceFrom(_current_target, true) > range) {
                    //trace("[SHIP] target has moved out of range");
                    _current_target = null;
                } else {
                    //trace("[SHIP] firing!");
                    var cannon_smoke:CannonSmoke = (FP.world.classFirst(CannonSmoke) as CannonSmoke);
                    var cannonball:Cannonball = FP.world.create(Cannonball, true) as Cannonball;
                    cannonball.damage = 10;
                    cannonball.x = this.x, cannonball.y = this.y;
                    cannonball.accuracy = getAccuracy();
                    cannonball.target(_current_target, true);
                    cannonball.shooter = this;
                    cannonball.fire();
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
            if (visible) checkInput();
            attack();
            if (_current_target && !(fsm.currentState is Attack)) {
                fsm.changeState(new Attack(this));
            }
            try {
                layer = -y;
            } catch(e:Error) {}
        }
    }   
}