 package ai.states {
    import flash.geom.Point;
    import flash.display.Graphics;
    
    import net.flashpunk.*;
    import net.flashpunk.tweens.misc.Alarm;
    
    import ai.pather.Pathfinder;
    import util.fsm.State;
    import world.entities.*;
    
    public class Seek extends State {
        private var _ship:EnemyShip;
        private var _point:Point;
        private var _pathfinder:Pathfinder;
        private var _when:int;
        
        public function Seek(self:EnemyShip, point:Point, when:int=0):void {
            _ship = self;
            _point = point;
            _pathfinder = new Pathfinder();
            _when = when;
        }
        
        override public function enter():void {
            // on entering the patrol state the AI will choose
            // a random node to go to within it's node space
            trace("[SEEK STATE] Entering seek state.");
            _ship.stop();
            _ship.arrived.add(nextState);
            FP.world.addTween(new Alarm(_when, function():void {
                trace("[SEEK STATE] searching for path");
                _pathfinder.findPath(_ship.point, _point, function(pth:Vector.<Point>):void {
                    if (pth == null) {
                        _ship.fsm.changeState(new Patrol(_ship));
                    } else {
                        _ship.moveTo(pth); 
                    }
                });
            }, Tween.ONESHOT), true);
        }
        
        private function nextState(s:Ship):void {
            _ship.fsm.nextState();
        }
        
        override public function exit():void {
            // truncate the patrol nodes vector and stop the ship
            trace("[SEEK STATE] Exiting seek state.");
            _ship.arrived.remove(nextState);
        }
    }
}