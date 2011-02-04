package ai.states {
    import flash.utils.getTimer;
    import flash.geom.Point;
    import flash.display.Graphics;
    
    import net.flashpunk.FP;
    
    import util.fsm.State;
    import ai.data.Blackboard;
    import ai.pather.*;
    import gfx.Hud;
    import util.ds.Vector2D;
    import world.Map;
    import world.entities.*;
    
    public class Patrol extends State {
        private var _ship:EnemyShip;
        private var _distance:int;
        private var _pathfinder:Pathfinder;
        private var _patrol_nodes:Vector.<Point>;
        private var _current_node:Point;
        private var _last_node:Node;
        private var _blackboard:Blackboard;
        private var _state_entered:Boolean;
        
        public function Patrol(self:EnemyShip):void {
            _ship = self;
            _pathfinder = new Pathfinder();
            _distance = 250;
            _blackboard = (FP.world as Map).blackboard;
            _patrol_nodes = new Vector.<Point>();
        }
        
        public function drawPatrolArea(g:Graphics):void {
            g.lineStyle(2, 0x0000FF);
            var patrol_length:int = _patrol_nodes.length;
            for (var i:int=0; i < patrol_length; i++) {
                g.drawCircle(_patrol_nodes[i].x, _patrol_nodes[i].y, Pathfinder.GRAPH_SCALE * 0.25);
            }
        }
        
        private function findPatrolNodes():void {
            var height:int = FP.screen.height;
            var width:int = FP.screen.width;
            for (var y:int=0; y < height; y+=Pathfinder.GRAPH_SCALE) {
                for (var x:int=0; x < FP.width; x+=Pathfinder.GRAPH_SCALE) { 
                    var node_vec:Vector2D = new Vector2D(x+(Pathfinder.GRAPH_SCALE/2), y + (Pathfinder.GRAPH_SCALE/2));
                    var point:Point = new Point(node_vec.x, node_vec.y);
                    if (_ship.position.dist(node_vec) < _distance && Pathfinder.getNodeForPoint(point) != null) {
                        _patrol_nodes.push(point);
                    }
                }
            }
        }
        
        private function findNextPoint():void {
            findPoint();
        }
        
        private function findPoint():void {
            var idx:int = Main.random(_patrol_nodes.length-1);
            _current_node = _patrol_nodes.splice(idx, 1)[0];
            var point:Point = new Point(_ship.position.x, _ship.position.y);
            _pathfinder.findPath(point, _current_node, function(pth:Vector.<Point>):void {
                _ship.moveTo(pth);
            });
        }
        
        private function arrived(s:Ship):void {
            //trace("[PATROL STATE] Ship has arrived. Moving again.");
            if (_patrol_nodes.length == 0 || Math.random() < .2) {
                _ship.fsm.changeState(new Patrol(_ship));
            } else {
                findNextPoint();
            }
        }
        
        override public function enter():void {
            // on entering the patrol state the AI will choose
            // a random node to go to within it's node space
            //trace("[PATROL STATE] Entering patrol state.");
            findPatrolNodes();
            findNextPoint();
            _ship.arrived.add(arrived);
        }
        
        override public function exit():void {
            // truncate the patrol nodes vector and stop the ship
            _patrol_nodes.length = 0;
            _ship.arrived.remove(arrived);
            //_ship.stop();
            //trace("[PATROL STATE] Exiting patrol state.");
        }
    }
}