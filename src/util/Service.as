package util {
    import flash.geom.Point;
    import flash.display.*;
    import flash.net.*;
    import flash.events.Event;
    import flash.system.Security;
    
    import net.flashpunk.FP;
    
    import util.Preloader;
    
    import gfx.Hud;
    
    public class Service {
        public static const MOCHI_ID:String = "2cccf04597805512";
        public static const LEADERBOARD_ID:String = "";
        
        public static const PLAYTOMIC_ID:int = 762;
        public static const PLAYTOMIC_GUID:String = "a71bf075-753b-4c83-8a69-2b46d505b4c0";
        
        public static const AGI_DEV_KEY:String = "f555f1780e3058bcd5c2359934cef066";
        public static const AGI_GAME_KEY:String = "islands-of-empire";
        
        private static var _instance:Service;
        private static var _initialized:Boolean;
        private static var _agi:Object;
        
        public function Service(p_key:SingletonBlocker):void {
            if (p_key == null) {
                throw new Error("Error: Instantiation failed: Use Service.instance instead of new.");
            }
            var agi_url:String = "http://agi.armorgames.com/assets/agi/AGI.swf";
            Security.allowDomain( agi_url );
            
            // Load the AGI
            var urlRequest:URLRequest = new URLRequest( agi_url );
            var loader:Loader = new Loader();
            loader.contentLoaderInfo.addEventListener( Event.COMPLETE, loadComplete );
            loader.load( urlRequest );
        }
        
        private function loadComplete(evt:Event):void {
            _agi = evt.currentTarget.content;
            Hud.instance.addChild(_agi as DisplayObject);
            _agi.init(AGI_DEV_KEY, AGI_GAME_KEY);
        }
        
        public static function get instance():Service {
            if (!_instance) {
                _instance = new Service(new SingletonBlocker());
            }
            return _instance;
        }
        
        public function connect():void {
            //Log.View(PLAYTOMIC_ID, PLAYTOMIC_GUID, Preloader.rootClip.loaderInfo.loaderURL);
        }
        
        public static function postScore(clip:DisplayObjectContainer):void {
            //var o:Object = { 
            //    n: [15, 14, 2, 6, 6, 10, 11, 12, 8, 15, 6, 1, 3, 1, 7, 11], 
            //    f: function (i:Number, s:String):String { 
            //           if (s.length == 16) return s; 
            //           return this.f(i+1, s + this.n[i].toString(16));
            //       }
            //};
            //var boardID:String = o.f(0,"");
            //MochiServices.connect(MOCHI_ID, clip);
            //MochiScores.showLeaderboard({boardID: boardID, score: Main.score, res:"450x600", width:200, height:300});
            clip.addChild(_agi as DisplayObject);
            _agi.initAGUI({ x:25, y:50 }); 
            _agi.showScoreboardSubmit(Main.score);
        }
        
        public static function showScores(clip:DisplayObjectContainer):void {
            clip.addChild(_agi as DisplayObject);
            _agi.initAGUI({ x:25, y:50 }); 
            _agi.showScoreboardList();
        }
        
        public static function logLevelEvent(evt:String, lvl:int):void {
            //Log.LevelCounterMetric(evt, lvl);
        }
        
        public static function logPlay(lvl:int):void {
            //Log.Play();
        }
        
        public static function logCustom(evt:String, value:*=null):void {
            //Log.CustomMetric(evt, value);
        }
        
        public static function dumpSaveData():void {
            var lso:SharedObject = SharedObject.getLocal('uncharted_waters4');
            var health:Array = [];
            for (var i:int=0; i < Main.TOTAL_SHIPS; i++) {
                if (Main.ships[i] == null) {
                    health[i] = null;
                } else {
                    health[i] = Main.ships[i].health;
                }
            }
            lso.data.upgrades = Main.upgrades;
            lso.data.health = health;
            lso.data.level = Main.level;
            lso.data.score = Main.currentScore;
            lso.flush();
        }
        
        private static function isEmpty(o:Object):Boolean {
            var isEmpty:Boolean = true;
            for (var n:String in o) { isEmpty = false; break; }
            return isEmpty;
        }
        
        public static function loadSaveData():Object {
            var lso:SharedObject = SharedObject.getLocal('uncharted_waters4');
            if (lso && lso.data && !isEmpty(lso.data)) {
                lso.data.level.start = new Point(lso.data.level.start.x, lso.data.level.start.y);
                lso.data.level.end = new Point(lso.data.level.end.x, lso.data.level.end.y);
                return lso.data;
            } else {
                return null;
            }
        }
    }
}
internal class SingletonBlocker {}