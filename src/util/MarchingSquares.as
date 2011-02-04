package util {
    import flash.geom.Point;
    import flash.display.BitmapData;
    
    public class MarchingSquares {
        private static const E:Point = new Point(1, 0);
        private static const NE:Point = new Point(1, -1);
        private static const N:Point = new Point(0, -1);
        private static const NW:Point = new Point(-1, -1);
        private static const W:Point = new Point(-1, 0);
        private static const SW:Point = new Point(-1, 1);
        private static const S:Point = new Point(0, 1);
        private static const SE:Point = new Point(1, 1);

        private var _data:BitmapData;

        public function MarchingSquares(data:BitmapData) {
            _data = data;
        }

        public function dispose():void {
            _data = null;
        }

        /**
         * Finds the perimeter between a set of opaque and transparent values which
         * begins at the specified pixel.
         * 
         * @return a closed, counterclockwise path that is a perimeter between a
         *         set of opaque and transparent values in the _data.
         * @throws ArgumentError
         *             if there is no perimeter at the specified initial point.
         */

        public function perimeter(initialX:int, initialY:int):Vector.<Point> {
            var initialValue:int = value(initialX, initialY);
            if (initialValue == 0 || initialValue == 15) {
                throw new ArgumentError("Supplied initial coordinates (" + initialX + ", " + initialY + ") do not lie on a perimeter.");
            }

            var perimeter:Vector.<Point> = new Vector.<Point>();
            var x:int = initialX;
            var y:int = initialY;
            var previous:Point = null;

            do {
                var direction:Point;
                switch (value(x, y)) {
                    case  1:
                        direction = N; break;
                    case  2:
                        direction = E; break;
                    case  3:
                        direction = E; break;
                    case  4:
                        direction = W; break;
                    case  5:
                        direction = N; break;
                    case  6:
                        direction = previous == N ? W : E; break;
                    case  7:
                        direction = E; break;
                    case  8:
                        direction = S; break;
                    case  9:
                        direction = previous == E ? N : S; break;
                    case 10:
                        direction = S; break;
                    case 11:
                        direction = S; break;
                    case 12:
                        direction = W; break;
                    case 13:
                        direction = N; break;
                    case 14:
                        direction = W; break;
                    default:
                        throw new Error("IllegalStateException"); break;
                }
                x += direction.x;
                y += direction.y;
                perimeter.push(new Point(x, y));
                previous = direction;
            } while (x != initialX || y != initialY);

            return perimeter;
        }

        private function value(x:int, y:int):int {
            var sum:int = 0;
            if (_data.getPixel32(x - 1, y - 1) >> 24) sum |= 1;
            if (_data.getPixel32(x, y - 1) >> 24) sum |= 2;
            if (_data.getPixel32(x - 1, y) >> 24) sum |= 4;
            if (_data.getPixel32(x, y) >> 24) sum |= 8;
            return sum;
        }
    }
}