package reactor {
    import org.osflash.signals.natives.NativeSignal;
    
    public class Reactor {
        {
            init();
        }
        private static const NUM_PROCESSES:int = 100;
        private static var _switchboard:Vector.<Fiber>;
        private static var _free_list:Vector.<int>;
        
        private static function init():void {
            _switchboard = new Vector.<Fiber>(NUM_PROCESSES, true);
            _free_list = new Vector.<int>();
            for (var i:int=0; i < NUM_PROCESSES; i++) {
                _free_list.push(i);
            }
        }
        
        public static function pump():void {
            if (_free_list.length == NUM_PROCESSES) return;
            for (var i:int=0; i < NUM_PROCESSES; i++) {
                if (_switchboard[i] == null) continue;
                _switchboard[i].run();
                if (_switchboard[i].did_fire) removeFiber(i);
            }
        }
        
        public static function callLater(callback:Function, thisArg:*=null, args:Array=null):void {
            if (!_free_list.length > 0) {
                throw new Error("Process list is exhausted. Please try your call again.");
            }
            var process_id:int = _free_list.shift();
            _switchboard[process_id] = new Fiber(callback, thisArg, args);
            //trace("[REACTOR] job added with process id", process_id);
        }
        
        public static function removeFiber(process_id:int):void {
            _switchboard[process_id] = null;
            _free_list.push(process_id);
        }
    }
}