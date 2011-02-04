 package ai.states {
    import util.fsm.State;
    import world.entities.EnemyShip;
    
    public class Hold extends State {
        private var _ship:EnemyShip;
        
        public function Hold(self:EnemyShip):void {
            _ship = self;
        }
        
        override public function enter():void {
            //trace("[HOLD STATE] Entering hold state.");
            _ship.stop();
        }
        
        override public function exit():void {
            //trace("[HOLD STATE] Exiting hold state.");
        }
    }
}