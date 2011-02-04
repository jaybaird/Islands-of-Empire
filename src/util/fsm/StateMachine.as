package util.fsm {
    import flash.utils.getTimer;
    
    public class StateMachine {
        public static const DEBUG:Boolean = true;
        
        private var _last_time:int;
        private var _current_state:State;
        private var _previous_state:State;
        private var _next_state:State;
        
        public function StateMachine(initial_state:State=null):void {
            _current_state = _previous_state = _next_state = null;
            _last_time = 0;
            if (initial_state != null) {
                _next_state = initial_state;
                nextState();
            }
        }
        
        public function setNextState(s:State):void {
            _next_state = s;
        }
        
        public function changeState(s:State):void {
            if (_current_state) {
                _current_state.exit();
                _previous_state = _current_state;
            }
            if (s) {
                _current_state = s;
                _current_state.enter();
            }
        }
        
        public function get currentState():State {
            return _current_state;
        }
        
        public function previousState():void {
            changeState(_previous_state);
        }
        
        public function nextState():void {
            changeState(_next_state);
        }
    }
}