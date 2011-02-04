 package ai.states {
    import flash.utils.getTimer;
    import flash.geom.Point;
    import flash.display.Graphics;
    
    import net.flashpunk.*;
    import net.flashpunk.tweens.misc.Alarm;
    
    import util.fsm.State;
    import world.Map;
    import world.entities.*;
    
    public class Attack extends State {
        private var _inactivity_timer:Tween;
        private var _ship:EnemyShip;
        
        public function Attack(self:EnemyShip):void {
            _ship = self;
            _inactivity_timer = FP.world.addTween(new Alarm(10, changeState, Tween.ONESHOT), true);
        }
        
        private function changeState():void {
            _ship.fsm.changeState(new Patrol(_ship));
        }
        
        private function resetTween():void {
            (_inactivity_timer as Alarm).reset(5);
        }
        
        override public function enter():void {
            //trace("[ATTACK STATE] Entering attack state.");
            _ship.stop();
            _ship.fired.add(resetTween);
            //var pos:Point = new Point(_ship.position.x, _ship.position.y);
            //(FP.world as Map).blackboard.write('known_ship_location', [pos, getTimer()]);
        }
        
        override public function exit():void {
            //trace("[ATTACK STATE] Exiting attack state.");
            _ship.fired.remove(resetTween);
        }
    }
}