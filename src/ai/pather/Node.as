package ai.pather {
    public class Node {
        public var x:int;
        public var y:int;
        
        public var connections:Vector.<Node>;
        
        public function Node(x:int, y:int):void {
            this.x = x, this.y = y;
            connections = new Vector.<Node>();
        }
    }
}