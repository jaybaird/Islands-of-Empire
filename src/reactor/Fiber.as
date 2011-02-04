package reactor {
    public class Fiber {
        public var did_fire:Boolean;
        
        private var _callback:Function;
        private var _thisArg:*;
        private var _args:Array;

        public function Fiber(callback:Function, thisArg:*, args:Array):void {
            _callback = callback;
            _thisArg = thisArg;
            _args = args;
            did_fire = false;
        }

        public function run():void {
            _callback.apply(_thisArg, _args);
            did_fire = true;
        }
    }
}