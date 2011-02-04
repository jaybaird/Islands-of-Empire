package levels {
    import flash.geom.Point;
    
    import util.LevelDesigner;
    
    public class Level {
        public static const TUTORIAL_DATA:Object = {
            "number": 1,
            "seed": 300,//17,
            "start":new Point(0, 238),
            "end":new Point(800, 380),
            "fog":true,
            "forts": 20,
            "fort_worth": 100,
            "ship_worth": 200,
            "path_points": 15,
            "enemy_ships": 3,
            "spawn_ships": 3,
            "inactivity_timer": 25
        };
        public static const END_DATA:Object = {
            "number": 21,
            "seed": 0,
            "start":new Point(0, 238),
            "end":new Point(800, 380),
            "forts": 0,
            "enemy_ships": 0,
            "spawn_ships": 0,
            "inactivity_timer": 2500
        }
        
        public function Level(n:int=1):void {}
        
        public static function loadLevel(level:int):Object {
            if (level == 1) {
                return TUTORIAL_DATA;
            } else if (level == 21) {
                return END_DATA;
            } else {
                var ll:Object = LevelDesigner.designLevel(level);
                ll.level = level;
                return ll;
            }
        }
    }
}