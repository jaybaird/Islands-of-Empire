package ai.spawngrid {
    import flash.geom.*;
    import flash.display.Graphics;
    
    import ai.pather.*;
    
    public class SpawnGrid {
        private var _width:int;
        private var _height:int;
        private var _point_count:int;
        private var _min_dist:Number
        private var _points:Vector.<Point>;
        
        public function SpawnGrid(w:int, h:int, min_dist:Number, point_count:int, check_grid:Boolean=true):void {
            _width = w, _height = h;
            _point_count = point_count;
            _min_dist = min_dist;
            _points = new Vector.<Point>();
            buildGrid(check_grid);
        }
        
        public function destroy():void {
            _points.length = 0;
        }
        
        public function get points():Vector.<Point> { return _points; }
        
        public function drawGrid(g:Graphics):void {
            g.beginFill(0x00ff00, .5);
            for (var i:int=0; i < _points.length; i++) {
                g.drawCircle(_points[i].x, _points[i].y, 5);
            }
            g.endFill();
        }
        
        private function generateRandomPoint(p:Point):Point {
            var r1:Number = Math.random(), r2:Number = Math.random();
            var radius:Number = _min_dist * (r1 + 1);
            var angle:Number = 2 * Math.PI * r2;
            return new Point(int(p.x + radius * Math.cos(angle)), int(p.y + radius * Math.sin(angle)));
        }
        
        private function checkDistance(p:Point):Boolean {
            for (var i:int=0; i < _points.length; i++) {
                if (Point.distance(p, _points[i]) < _min_dist) {
                    return true;
                }
            }
            return false;
        }
        
        private function buildGrid(check_grid:Boolean):void {
            var i:int = 0;
            var bounds:Rectangle = new Rectangle(0, 0, _width, _height);
            if (check_grid) {
                _points.push(Pathfinder.getRandomPoint());
            } else {
                _points.push(new Point(Main.random(_width-1), Main.random(_height-1)));
            }
            while (i < _point_count) {
                var idx:int = Main.random(_points.length-1);
                var p:Point = _points[idx];
                var newPoint:Point = generateRandomPoint(p);
                if (bounds.containsPoint(newPoint)) {
                    if (check_grid) {
                        var node:Node = Pathfinder.getNodeForPoint(newPoint);
                        if (node != null && !checkDistance(newPoint)) {
                            var p2:Point = Pathfinder.getPointForNode(node);
                            _points.push(p2);
                            i++;
                        }
                    } else {
                        if (!checkDistance(newPoint)) {
                            _points.push(newPoint);
                            i++;
                        }
                    }
                }
            }
        }
    }
}