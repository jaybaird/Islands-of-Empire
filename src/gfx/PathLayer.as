package gfx {
    import flash.geom.Point;
    import flash.display.*;
    import flash.events.*;
    
    import net.flashpunk.FP;
    import org.osflash.signals.Signal;
    
    import world.Map;
    import util.SoundBoard;
    import world.entities.Zone;
    import ai.pather.Pathfinder;
    
    public class PathLayer extends Sprite {
        public static const POINT_TOO_CLOSE:int = 0;
        public static const POINT_NOT_VALID:int = 1;
        public static const PATH_COMPLETE:int = 2;
        
        private var _map:Map;
        private var _zone:Bitmap;
        private var _path:Vector.<Point>;
        private var _pathfinder:Pathfinder;
        private var _map_points:Vector.<MapPoint>;
        private var _waypoint_added:Signal;
        private var _drag_stopped:Signal;
        private var _point_deleted:Signal;
        private var _messaging:Signal;
        private var _delete_flag:Boolean;
        private var _check_zone:Boolean;
        
        public function PathLayer():void {
            _map = FP.world as Map;
            _pathfinder = _map.pathfinder;
            _waypoint_added = new Signal(MapPoint);
            _drag_stopped = new Signal(MapPoint);
            _point_deleted = new Signal(MapPoint);
            _messaging = new Signal(int);
            _map_points = new Vector.<MapPoint>();
            _zone = new Zone.ZONE();
            _delete_flag = true;
            _check_zone = true;
            addEventListener(Event.ADDED_TO_STAGE, init);
            addEventListener(Event.REMOVED_FROM_STAGE, removed);
        }
        
        private function removed(evt:Event):void {
            removeEventListener(Event.REMOVED_FROM_STAGE, removed);
            removeChild(_zone);
        }
        
        private function init(evt:Event):void {
            removeEventListener(Event.ADDED_TO_STAGE, init);
            addEventListener(MouseEvent.CLICK, mouseClick);
            var shape:Shape = new Shape();
            shape.graphics.beginFill(0, 0);
            shape.graphics.drawRect(0, 0, FP.width, FP.height);
            addChild(shape);
            _zone.x = Main.level.end.x - _zone.width, _zone.y = Main.level.end.y - _zone.height/2;
            addChildAt(_zone, 0);
        }
        
        private function checkPoint(mp:MapPoint):Boolean {
            if (mp.point == null) return true;
            var collide:Boolean = _map_points.every(function(item:MapPoint, idx:int, vec:Vector.<MapPoint>):Boolean {
                if (!item || item === mp || item.point == null) return true;
                return !item.hitTestObject(mp);
            });
            if (!collide) {
                _messaging.dispatch(POINT_TOO_CLOSE);
                return false;
            } else if (Pathfinder.getNodeForPoint(mp.point) == null) {
                _messaging.dispatch(POINT_NOT_VALID);
                return false;
            }
            return true;
        }
        
        private function mouseClick(evt:MouseEvent):void {
            if (evt.eventPhase == EventPhase.BUBBLING_PHASE) return;
            SoundBoard.playEffect("waypoint");
            FP.point.x = evt.stageX, FP.point.y = evt.stageY;
            addWaypoint(FP.point.clone());
        }
        
        public function addWaypoint(p:Point):MapPoint {
            if (p == null) return null;
            var point:MapPoint = new MapPoint(p);
            point.x = p.x, point.y = p.y;
            addChild(point);
            if (checkPoint(point)) {
                _map_points.push(point);
                _waypoint_added.dispatch(point);
                if (_check_zone && _zone.hitTestObject(point)) {
                    trace("path complete");
                    _messaging.dispatch(PATH_COMPLETE);
                }
                point.pointDeleted.add(pointDelete);
                point.dragStopped.add(dragStop);
                point.dragStopped.add(updateMap);
                point.dragStopped.add(checkPoint);
            } else {
                removeChild(point);
            }
            updateMap(point);
            return point
        }
        
        private function pointDelete(mp:MapPoint):void {
            _point_deleted.dispatch(mp);
        }
        
        private function dragStop(mp:MapPoint):void {
            _drag_stopped.dispatch(mp);
        }
        
        public function removeWaypoint(p:MapPoint):void {
            var idx:int = _map_points.indexOf(p);
            if (contains(_map_points[idx])) {
                removeChild(_map_points[idx]);
                _map_points[idx] = null;
                updateMap(null);
            }
        }
        
        public function containsWaypoint(m:MapPoint):Boolean {
            for (var i:int = 0; i < _map_points.length; i++) {
                if (_map_points[i].point.equals(m.point)) return true;
            }
            return false;
        }
        
        private function updateMap(mp:MapPoint):void {
            _pathfinder.findPathThroughPoints(points, new Vector.<Point>(), function(pth:Vector.<Point>):void {
                _path = pth;
                Pathfinder.drawPath(pth, graphics);
            });
        }
        
        public function addPoint(p:Point):void {
            var mp:MapPoint = addWaypoint(p);
            mp.mouseEnabled = false;
            mp.mouseChildren = false;
        }
        public function set checkZone(value:Boolean):void { _check_zone = value; }
        public function get messaging():Signal { return _messaging; }
        public function get waypointAdded():Signal { return _waypoint_added; }
        public function get dragStopped():Signal { return _drag_stopped; }
        public function get pointDeleted():Signal { return _point_deleted; }
        public function get points():Vector.<Point> {
            var pts:Vector.<Point> = new Vector.<Point>();
            _map_points.forEach(function(item:MapPoint, index:int, vec:Vector.<MapPoint>):void {
                if (item && item.point != null) {
                    pts.push(item.point);
                } else {
                    item = null;
                }
            });
            return pts;
        }
        public function get path():Vector.<Point> { return _path; }
        public function get deleteFlag():Boolean { return _delete_flag; }
        public function set deleteFlag(value:Boolean):void { _delete_flag = value; }
    }
}