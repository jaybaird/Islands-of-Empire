package util {
    import flash.geom.*;
    import flash.utils.*;
    import flash.errors.*;
    import flash.display.*;
    
    import net.flashpunk.FP;
    import org.as3commons.lang.DictionaryUtils;
    
    import gfx.*;
    import world.BaseMap;
    import ai.pather.Pathfinder;
    
    public class LevelDesigner {
        private static var _maps_seen:Dictionary;
        {
            _maps_seen = new Dictionary();
        }
        
        public function LevelDesigner():void {}
        
        private static function countPixels(bmp:BitmapData):Number {
            var start:int = getTimer();
            var colored:int = 0;
            var bytes:ByteArray = bmp.getPixels(new Rectangle(0, 0, FP.width, FP.height));
            bytes.position = 0;
            for (var i:int=2; i < bytes.length; i+=128) {
                colored += bytes[i];
            }
            return (colored/255) / (bytes.length/128);
        }
        
        private static function findStart(edge:int=0):Point {
            var p:Point = new Point(edge, Main.random(500, 100));
            while (Pathfinder.getNodeForPoint(p) == null) {
                p.y = Main.random(500, 100);
            }
            trace(p.toString());
            return p;
        }
        
        private static function findEnd():Point {
            return findStart(800);
        }
        
        private static function getDifficulty(lvl:int):Object {
            if (lvl < 3) {
                return {
                    "percentage": .13,
                    "forts": Main.random(15, 13),
                    "fort_worth": 200,
                    "ship_worth": 300,
                    "enemy_ships": Main.random(4, 2),
                    "inactivity_timer": Main.random(25, 20)
                };
            } else if (lvl < 6) {
                return {
                    "percentage": .15,
                    "forts": Main.random(20, 15),
                    "fort_worth": 300,
                    "ship_worth": 400,
                    "enemy_ships": Main.random(4, 3),
                    "inactivity_timer": Main.random(20, 15)
                };
            } else if (lvl < 9) {
                return {
                    "percentage": .17,
                    "forts": Main.random(25, 20),
                    "fort_worth": 500,
                    "ship_worth": 600,
                    "enemy_ships": Main.random(6, 4),
                    "inactivity_timer": Main.random(15, 10)
                };
            } else if (lvl <= 12) {
                return {
                    "percentage": .19,
                    "forts": Main.random(30, 25),
                    "fort_worth": 700,
                    "ship_worth": 800,
                    "enemy_ships": Main.random(7, 5),
                    "inactivity_timer": Main.random(20, 15)
                };
            }
            return {};
        }
        
        private static function verifyStartToEnd(m:BaseMap):Array {
            var pathfinder:Pathfinder = new Pathfinder();
            m.buildIslands();
            Pathfinder.init(m, true);
            var s:Point = findStart();
            var e:Point = findEnd();
            var path:Vector.<Point> = pathfinder.findPath(s, e, null, true);
            var count:int = 0;
            while (path == null && count < 5) {
                s = findStart(), e = findEnd();
                path = pathfinder.findPath(s, e, null, true);
                count++;
            }
            if (path == null && count == 5) {
                return null;
            } else {
                return [s, e];
            }
        }
        
        public static function designLevel(lvl:int):Object {
            // build a basemap with an available value
            var start_time:int = getTimer();
            var fill_color:uint = 0;
            var seed:int = Main.random(int.MAX_VALUE, int.MIN_VALUE);
            while (DictionaryUtils.containsKey(_maps_seen, seed) || seed == 0) {
                seed = Main.random(int.MAX_VALUE, int.MIN_VALUE);
            }
            var bmap:BaseMap = new BaseMap(seed);
            var bmp:BitmapData = MapUtils.mapData;
            var rect:Rectangle;
            var p:Point = MapUtils.getFirstPixel(bmp, 0xff000000);
            var difficulty:Object = getDifficulty(lvl);
            var pixels:Number = countPixels(bmp);
            bmp.floodFill(p.x, p.y, fill_color);
            rect = bmp.getColorBoundsRect(fill_color, fill_color);
            while ((rect.width != FP.width && rect.height != FP.height) || pixels < difficulty.percentage) {
                bmap = new BaseMap(Main.random(int.MAX_VALUE, int.MIN_VALUE));
                bmp = MapUtils.mapData;
                p = MapUtils.getFirstPixel(bmp, 0xff000000);
                bmp.floodFill(p.x, p.y, fill_color);
                rect = bmp.getColorBoundsRect(fill_color, fill_color); 
                pixels = countPixels(bmp);               
            }
            var points:Array = verifyStartToEnd(bmap);
            if (points == null) {
                _maps_seen[seed] = true;
                trace("[LEVEL DESIGNER] going deeper...");
                return designLevel(lvl);
            }
            trace(points.toString());
            trace("[LEVEL DESIGNER] designLevel took: ", getTimer() - start_time);
            difficulty.number = lvl;
            difficulty.seed = seed;
            difficulty.start = points[0], difficulty.end = points[1];
            _maps_seen[seed] = true;
            return difficulty;
        }
    }
}