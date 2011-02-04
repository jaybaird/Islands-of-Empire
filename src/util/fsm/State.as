package util.fsm {
    public class State {
        protected var _last_update:int;
        protected var _parent:State;
        
        public function State(p:State=null):void {
            _parent = p;
        }
        
        public function get parent():State { return _parent; }
        
        // called when entering the state
        public function enter():void {}
        
        // called every frame while the state is executing
        public function update(time:int):void {}
        
        // called when exiting the state
        public function exit():void {}
        
        public function restart():void {}
    }
}