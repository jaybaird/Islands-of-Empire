package ai.pather {
    public class PathNode {
        private var _parent:Node;

        public var f:int;
        public var h:int;
        public var g:int;
        public var parent:PathNode;
        
        public function PathNode(node:Node):void {
            if (node == null) throw new Error("Node was null. Can't create a PathNode without a parent.");
            _parent = node;
        }
        
        public function equals(n:PathNode):Boolean {
            return (n.x == _parent.x && n.y == _parent.y);
        }
        
        public function get node():Node { return _parent; }
        public function get connections():Vector.<Node> { return _parent.connections; }
        public function get x():int { return _parent.x; }
        public function get y():int { return _parent.y; }
    }
}