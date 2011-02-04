package ai.pather {
    import flash.geom.*;
    import flash.display.Graphics;
    import flash.utils.Dictionary;
    
    import net.flashpunk.FP;
    import org.osflash.signals.Signal;
    
    import world.*;
    import world.entities.*;
    import util.ds.NodeHeap;
    import gfx.Hud;
    import reactor.Reactor;
    
    public class Pathfinder {
        private static const STRAIGHT_COST:Number = 1.0;
        private static const DIAGONAL_COST:Number = Math.SQRT2;
        public static const GRAPH_SCALE:int = 10;
        
        private static var _initialized:Boolean;
        private static var _width:int;
        private static var _height:int;
        private static var _nodes:Vector.<Vector.<Node>>;
        
        private var _open:NodeHeap;
        private var _closed:Dictionary;
        
        private var _callback:Function;
        private var _result:int;
        private var _fired:Boolean;
        
        private var _start:PathNode;
        private var _end:PathNode;
        
        private var _p1:Point;
        private var _p2:Point;
        
        private var _node_cache:Dictionary;
        private const _findPathThroughPoints:Function = findPathThroughPoints;
        
        public function Pathfinder():void {
            
        }
        
        public static function init(m:BaseMap, reload:Boolean=false):void {
            if (_initialized && !reload) return;
            trace("[PATHFINDER] reticulating splines...");                                                                                                                                                                                                                                                                      
            _width = FP.screen.width / GRAPH_SCALE;
            _height = FP.screen.height / GRAPH_SCALE;
            _nodes = new Vector.<Vector.<Node>>(_height, true);
            var r:int, c:int;
            for (r=0; r < _height; r++) {
                _nodes[r] = new Vector.<Node>(_width, true);
                for (c=0; c < _width; c++) {
                    _nodes[r][c] = null;
                }
            }
            var islands:Vector.<Island> = m.islands;
            var islands_length:int = islands.length;
            for (r=0; r < _height; r++) {
                for (c=0; c < _width; c++) {
                    var collision:Boolean = false;
                    for (var i:int=0; i < islands_length; i++) {
                        var island:Island = islands[i];
                        if (island.collideRect(island.x, island.y, c * GRAPH_SCALE, r * GRAPH_SCALE, GRAPH_SCALE, GRAPH_SCALE)) {
                            collision = true;
                            break;
                        }
                    }
                    // collideRect(type:String, rX:Number, rY:Number, rWidth:Number, rHeight:Number):Entity
                    if (!collision) {
                        _nodes[r][c] = new Node(c, r);
                    }
                }
            }
            makeConnections();
            _initialized = true;
        }
        
        public function get nodes():Vector.<Vector.<Node>> { return _nodes; }
        
        private function getPathNode(n:Node):PathNode {
            var path_node:PathNode = _node_cache[n];
            if (path_node == null) {
                path_node = new PathNode(n);
                _node_cache[n] = path_node;
            }
            return path_node;
        }
        
        public static function getRandomNode(bounds:Rectangle=null):Node {
            var node:Node = null;
            do {
                var r:int = Main.random(_nodes.length-1);
                var c:int = Main.random(_nodes[r].length-1);
                node = _nodes[r][c];
                if (bounds && node && bounds.containsPoint(getPointForNode(node))) {
                    return node
                }
            } while (node == null);
            return node;
        }
        
        public static function getRandomPoint(bounds:Rectangle=null):Point {
            return getPointForNode(getRandomNode(bounds));
        }

        public function getRandomPointFromPoint(p1:Point, mindist:Number):Point {
            var r1:Number = Math.random(), r2:Number = Math.random();
            var radius:Number = mindist * (r1 + 1);
            var angle:Number = 2 * Math.PI * r2;
            return new Point(p1.x + radius * Math.cos(angle), p1.y + radius * Math.sin(angle));
        }
        
        public function getRandomNodeFromPoint(p1:Point, mindist:Number):Node {
            var p:Point = getRandomPointFromPoint(p1, mindist);
            var node:Node = getNodeForPoint(p);
            while (node == null) {
                p = getRandomPointFromPoint(p1, mindist);
                node = getNodeForPoint(p);
            }
            return node;
        }
        
        public function findPath(p1:Point, p2:Point, cb:Function=null, blocking:Boolean=false):Vector.<Point> {
            if (!_initialized) { trace("[PATHFINDER] NOT INITIALIZED!"); return null; }
            _fired = false;
            _callback = cb;
            _result = -2;
            _open = new NodeHeap(_width * _height);
            _closed = new Dictionary(true);
            _node_cache = new Dictionary(true);
            
            var start_node:Node = getNodeForPoint(p1);
            var end_node:Node = getNodeForPoint(p2);
            if (!start_node || !end_node) { 
                trace("[PATHFINDER] start or end point was null."); 
                cb(null); 
                return null;
            }
            
            _p1 = p1, _p2 = p2;
            
            _start = getPathNode(start_node);
            _end = getPathNode(end_node);
            
            _start.g = 0, _start.h = diagonal(_start), _start.f = _start.g + _start.h;
            
            if (blocking) {
                return doBlockingSearch(_start);
            } else {
                doSearch(_start);
                return null;
            }
        }
        
        public function findPathThroughPoints(points:Vector.<Point>, path:Vector.<Point>=null, cb:Function=null):void {
            // finds a path through all the points
            if (points.length <= 1) {
                cb(path);
            } else {
                findPath(points[0], points[1], function(pth:Vector.<Point>):void {
                    if (pth == null) {
                        cb(null);
                    } else {
                        Reactor.callLater(_findPathThroughPoints, this, [points.slice(1), path.concat(pth), cb]);
                    }
                });
            }
        }
        
        private function doBlockingSearch(node:PathNode):Vector.<Point> {
            if (_end == null) {
                return null;
            }
            var result:int;
            while (true) {
                result = search(node);
                if (result == 0) {
                    node = (_open.dequeue() as PathNode);
                } else {
                    break;
                }
            }
            if (result == 1) {
                return path;
            } else {
                return null;
            }
        }
        
        private function doSearch(node:PathNode):void {
            if (_end == null) {
                hasResult(-1);
            }
            var result:int;
            for (var i:int = 0; i < 100; i++) {
                result = search(node);
                if (result == 0) {
                    node = (_open.dequeue() as PathNode);
                } else {
                    break;
                }
            }
            if (result < 0 || result > 0) {
                hasResult(result);
            } else {
                Reactor.callLater(doSearch, this, [(_open.dequeue() as PathNode)]);
            }
        }
        
        private function fireCallback():void {
            //trace("[PATHFINDER] firing callback and releasing pather");
            _callback((_result < 0) ? null : this.path);
            _fired = true;
        }
        
        private function hasResult(result:int):void {
            _result = result;
            if (_callback != null && !_fired) {
                fireCallback();
            }
        }
        
        private function search(node:PathNode):int {
            var result:int;
            if (node.equals(_end)) {
                //trace("[PATHFINDER] found path!");
                return 1;
            }
            var num_connections:int = node.connections.length;
            for (var i:int=0; i < num_connections; i++) {
                var test:PathNode = getPathNode(node.connections[i]);
                var cost:Number = STRAIGHT_COST;
                if (!((node.x == test.x) || (node.y == test.y))) cost = DIAGONAL_COST;
                var g:Number = node.g + cost;
                var h:Number = diagonal(test);
                var f:Number = g + h;
                if (_open.contains(test) || _closed[test]) {
                    if (test.f > f) {
                        test.f = f, test.g = g, test.h = h, test.parent = node;
                    }
                } else {
                    test.f = f, test.g = g, test.h = h, test.parent = node;
                    _open.enqueue(test);
                }
            }
            _closed[node] = true;
            if (_open.size() == 0) {
                trace("[PATHFINDER] no path found.");
                result = -1;
            } else {
                result = 0;
            }
            return result;
        }
        
        private function walkable3(a:PathNode, b:PathNode):Boolean {
            if (!a || !b) return false;
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

            if (yLonger) {
                for (var i:int = 0; i != longLen; i += inc) {
                    if (_nodes[int(a.y+i)][int(a.x + i*multDiff)] == null) return false;
                }
            } else {
                for (i = 0; i != longLen; i += inc) {
                    if (_nodes[int(a.y+i*multDiff)][int(a.x+i)] == null) return false;
                }
            }
            return true;
        }
        
        final public function get path():Vector.<Point> {
            var path:Vector.<PathNode> = new Vector.<PathNode>();
            var current:PathNode = _end;
            var last:PathNode;
            var ptr:PathNode = current.parent;
            var iter:int = 0;
            path.push(current);
            while(current != _start) {
                if (current == null || ptr == null) {
                    point_path = null;
                    break;
                }
                while(walkable3(current, ptr)) {
                    last = ptr;
                    ptr = ptr.parent;
                }
                if (!last) {
                    path.unshift(ptr);
                    current = ptr;
                    if (current)
                        ptr = current.parent;
                } else {
                    path.unshift(last);
                    current = last;
                    if (current)
                        ptr = current.parent;
                    last = null;
                }
            }
            var point_path:Vector.<Point> = new Vector.<Point>(path.length);
            var path_length:int = path.length;
            for (var i:int=0; i < path_length; i++) {
                if (i==0) {
                    point_path[i] = _p1;
                } else if (i==path_length-1) {
                    point_path[i] = _p2;
                } else {
                    point_path[i] = getPointForNode(path[i].node);
                }
            }
            return point_path;
        }
        
        private function diagonal(node:PathNode):Number {
            var dx:Number = (node.x - _end.x) < 0 ? -(node.x - _end.x) : (node.x - _end.x);
            var dy:Number = (node.y - _end.y) < 0 ? -(node.y - _end.y) : (node.y - _end.y);
            var diag:Number = (dx < dy) ? dx : dy;
            var straight:Number = dx + dy;
            return DIAGONAL_COST * diag + STRAIGHT_COST * (straight - 2 * diag);
        }
        
        public static function drawGraph(g:Graphics):void {
            var node:Node;
            var r:int, c:int, i:int;
            for (r=0; r < _height; r++) {
                for (c=0; c < _width; c++) {
                    node = _nodes[r][c];
                    if (!node) continue;
                    var connections_length:int = node.connections.length;
                    g.drawCircle((node.x * GRAPH_SCALE) + (GRAPH_SCALE/2), (node.y * GRAPH_SCALE) + (GRAPH_SCALE/2), GRAPH_SCALE * .1);
                    for (i=0; i < connections_length; i++) {
                        g.moveTo((node.x * GRAPH_SCALE) + (GRAPH_SCALE/2), (node.y * GRAPH_SCALE) + (GRAPH_SCALE/2));
                        g.lineTo((node.connections[i].x * GRAPH_SCALE) + (GRAPH_SCALE/2), (node.connections[i].y  * GRAPH_SCALE) + (GRAPH_SCALE/2));
                    }
                }
            }
        }
        
        public static function drawPath(path:Vector.<Point>, g:Graphics):void{
            if (path == null) return;
            var i:int = 0, path_length:int = path.length;
            g.clear();
            g.lineStyle(1, 0xcccccc, .3);
            for(i = 0; i < path_length; i++){
                var node:Point = path[i];
                //g.drawCircle(node.x, node.y, GRAPH_SCALE * 0.25);
                if(i > 0){
                    g.moveTo(node.x, node.y);
                    g.lineTo(path[i - 1].x , path[i - 1].y );
                }
            }
        }
        
        public static function getNormalizedPoint(p:Point):Point {
            return getPointForNode(getNodeForPoint(p));
        }
        
        public static function getNodeForPoint(p:Point):Node {
            if (p == null) return null;
            if (p.x >= FP.screen.width) p.x = FP.screen.width-1;
            if (p.y >= FP.screen.height) p.y = FP.screen.height-1;
            return _nodes[int(p.y/GRAPH_SCALE)][int(p.x/GRAPH_SCALE)];
        }
        
        public static function getPointForNode(n:Node):Point {
            if (n == null) return null;
            return new Point((n.x * GRAPH_SCALE) + (GRAPH_SCALE/2), (n.y * GRAPH_SCALE) + (GRAPH_SCALE/2));
        }
        
        private static function makeConnections():void {
            var r:int, c:int;
            for (r = 0; r < _height; r++) {
                for (c = 0; c < _width; c++) {
                    if (!_nodes[r][c]) continue;
                    if (c+1 != _width && _nodes[r][c+1]) {
                        _nodes[r][c].connections.push(_nodes[r][c+1]);
                        _nodes[r][c+1].connections.push(_nodes[r][c]);
                    }
                    if (r+1 != _height && _nodes[r+1][c]) {
                        _nodes[r][c].connections.push(_nodes[r+1][c]);
                        _nodes[r+1][c].connections.push(_nodes[r][c]);
                    }
                    if (r+1 != _height && c+1 != _width && _nodes[r+1][c+1]) {
                        _nodes[r][c].connections.push(_nodes[r+1][c+1]);
                        _nodes[r+1][c+1].connections.push(_nodes[r][c]);
                    }
                    if (r-1 >= 0 && c+1 != _width && _nodes[r-1][c+1]) {
                        _nodes[r][c].connections.push(_nodes[r-1][c+1]);
                        _nodes[r-1][c+1].connections.push(_nodes[r][c]);
                    }
                }
            }
        }
    }
}