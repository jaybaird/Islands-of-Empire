package util {
    import flash.geom.*;
    import flash.geom.Rectangle;
    import flash.display.BitmapData;
    
    public class MapUtils {
        private static var _mini_map:BitmapData;
        private static var _map_data:BitmapData;
        
        public static function set mapData(value:BitmapData):void {
            _map_data = value;
            var amount:Number = 4;
            var scale_factor:Number = 1 / amount;
            var scale_matrix:Matrix = new Matrix();
            _mini_map = new BitmapData(scale_factor * value.width, 
                scale_factor * value.height, true, 0x00000000);
            scale_matrix.identity();
            scale_matrix.scale(scale_factor, scale_factor);
            _mini_map.draw(value, scale_matrix);
        }
        public static function get mapData():BitmapData { return _map_data; }
        public static function get miniMap():BitmapData { return _mini_map; }
        
        public static function getFirstPixel(bmd:BitmapData, color:uint=0x01):Point {
            var hit_rect:Rectangle = new Rectangle(0, 0, bmd.width, 1);
            var p:Point = new Point();
            for( hit_rect.y = 0; hit_rect.y < bmd.height; hit_rect.y++ ) {
                if( bmd.hitTest(p, color, hit_rect)) {
                    var hit_bmd:BitmapData = new BitmapData(bmd.width, 1, true, 0);
                    hit_bmd.copyPixels(bmd, hit_rect, p);
                    return hit_rect.topLeft.add(hit_bmd.getColorBoundsRect(0xFF000000, 0, false).topLeft);
                }
            }
            return null;
        }
        
        public static function getFirstNonTransparentPixel(bmd:BitmapData):Point {
            return getFirstPixel(bmd);
        }
        
        public static function perimeter(data:BitmapData, simplify:Boolean=false):Vector.<Point> {
            var p:Point = getFirstNonTransparentPixel(data);
            var marchingSquares:MarchingSquares = new MarchingSquares(data);
            var perimeter:Vector.<Point> = marchingSquares.perimeter(p.x, p.y);
            marchingSquares.dispose();
            return perimeter;
        }
        
        public static function collideRay(a:Point, b:Point, check_func:Function):Boolean {
            if (!a || !b || !_map_data) return false;
            var shortLen:int = b.y-a.y;
            var longLen:int = b.x-a.x;
            var yLonger:Boolean = true;
            if ((shortLen ^ (shortLen >> 31)) - (shortLen >> 31) > (longLen ^ (longLen >> 31)) - (longLen >> 31)) {
              shortLen ^= longLen;
              longLen ^= shortLen;
              shortLen ^= longLen;
            } else {
              yLonger = false;
            }
            var inc:int = longLen < 0 ? -1 : 1;
            var multDiff:Number = longLen == 0 ? shortLen : shortLen / longLen;
            var result:Boolean;
            if (yLonger) {
                for (var i:int = 0; i != longLen; i += inc) {
                    result = check_func(int(a.x + i*multDiff), int(a.y+i), _map_data);
                    if (result) return true;
                }
            } else {
                for (i = 0; i != longLen; i += inc) {
                    result = check_func(int(a.x+i), int(a.y+i*multDiff), _map_data);
                    if (result) return true;
                }
            }
            return false;
        }
        
        public static function pixelate(data:BitmapData):BitmapData {
            var amount:Number = 2;
            var scale_factor:Number = 1 / amount;
            var scale_matrix:Matrix = new Matrix();
            var temp:BitmapData = new BitmapData(scale_factor * data.width, 
                scale_factor * data.height, true, 0x00000000);
            
            scale_matrix.identity();
            scale_matrix.scale(scale_factor, scale_factor);
            temp.draw(data, scale_matrix);
            scale_matrix.identity();
            scale_matrix.scale(amount, amount);
            data.fillRect(data.rect, 0);
            data.draw(temp, scale_matrix);

            return data;
        }
        
        public static function pointOnLine(a:Point, b:Point, d:Number):Point {
            if (!a || !b) return null;
            var shortLen:int = b.y-a.y;
            var longLen:int = b.x-a.x;
            var yLonger:Boolean = true;
            if ((shortLen ^ (shortLen >> 31)) - (shortLen >> 31) > (longLen ^ (longLen >> 31)) - (longLen >> 31)) {
              shortLen ^= longLen;
              longLen ^= shortLen;
              shortLen ^= longLen;
            } else {
              yLonger = false;
            }
            var inc:int = longLen < 0 ? -1 : 1;
            var multDiff:Number = longLen == 0 ? shortLen : shortLen / longLen;
            var p:Point = new Point();
            if (yLonger) {
                for (var i:int = 0; i != longLen; i += inc) {
                    p.x = int(a.x + i*multDiff), p.y = int(a.y+i);
                    if (Point.distance(a, p) >= d) return p;
                }
            } else {
                for (i = 0; i != longLen; i += inc) {
                    p.x = int(a.x+i), p.y = int(a.y+i*multDiff);
                    if (Point.distance(a, p) >= d) return p;
                }
            }
            return null;
        }
    }
}