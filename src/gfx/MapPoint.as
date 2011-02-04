package gfx {
    import flash.events.Event;
    import flash.events.MouseEvent;
    import flash.geom.Point;
    import flash.display.*;

    import net.flashpunk.FP;
    import org.osflash.signals.Signal;
    import net.flashpunk.graphics.Emitter;

    import effects.Puff;
    import util.SoundBoard;
    import ai.pather.Pathfinder;

    public class MapPoint extends Sprite {
        [Embed(source = '/assets/sprites/trash_closed.png')]  private static const TRASH_CLOSED:Class;
        [Embed(source = '/assets/sprites/trash_open.png')]  private static const TRASH_OPEN:Class;
    
        private var _point:Point;
        private var _ecks:Shape;
        private var _drag_stopped:Signal;
        private var _point_deleted:Signal;
    
        private static const _trash_open:Bitmap = new TRASH_OPEN();
        private static const _trash_closed:Bitmap = new TRASH_CLOSED();

        public function MapPoint(point:Point):void {
            _point = point;
            _ecks = new Shape();
            _drag_stopped = new Signal(MapPoint);
            _point_deleted = new Signal(MapPoint);
            buttonMode = true;
            useHandCursor = true;
            addEventListener(Event.ADDED_TO_STAGE, init);
        }
    
        public function get dragStopped():Signal { return _drag_stopped; }
        public function get pointDeleted():Signal { return _point_deleted; }
    
        private function init(evt:Event):void {
            removeEventListener(Event.ADDED_TO_STAGE, init);
            addEventListener(MouseEvent.MOUSE_DOWN, mouseDown);
            addEventListener(MouseEvent.MOUSE_UP, mouseReleased);
            drawPoint();
            _ecks.scaleX = _ecks.scaleY = 1.5;
            _ecks.x = -4 * _ecks.scaleX, _ecks.y = -4 * _ecks.scaleY;
        }
    
        private function mouseDown(evt:MouseEvent):void {
            startDrag();
            if (evt.stageX - 25 < 25) {
                _trash_open.x = evt.stageX + 15;
                _trash_closed.x = evt.stageX + 15;
            } else {
                _trash_open.x = evt.stageX - 25;
                _trash_closed.x = evt.stageX - 25;
            }
            if (evt.stageY - 25 < 25) {
                _trash_open.y = evt.stageY + 15;
                _trash_closed.y = evt.stageY + 15;
            } else {
                _trash_open.y = evt.stageY - 25;
                _trash_closed.y = evt.stageY - 25;
            }
            (parent as Sprite).graphics.clear();
            if ((parent as PathLayer).deleteFlag) {  
                parent.addChildAt(_trash_closed, 0);
                addEventListener(MouseEvent.MOUSE_MOVE, mouseMove);
            }
        }
    
        private function mouseMove(evt:MouseEvent):void {
            if (hitTestObject(_trash_closed)) {
                if (parent.contains(_trash_closed)) parent.removeChild(_trash_closed);
                parent.addChildAt(_trash_open, 0);
            } else {
                if (parent.contains(_trash_open)) parent.removeChild(_trash_open);
                parent.addChildAt(_trash_closed, 0);
            }
        }
    
        private function mouseReleased(evt:MouseEvent):void {
            stopDrag();
            removeEventListener(MouseEvent.MOUSE_MOVE, mouseMove);
            FP.point.x = evt.stageX, FP.point.y = evt.stageY;
            var removed:Boolean;
            var puff:Emitter = (FP.world.classFirst(Puff) as Puff).emitter;
            if ((parent as PathLayer).deleteFlag && hitTestObject(_trash_open)) {
                _point = null;
                _drag_stopped.dispatch(this);
                _drag_stopped.removeAll();
                removed = true;
            } else {
                if (Pathfinder.getNodeForPoint(FP.point)) {
                    _point = FP.point.clone();
                    _drag_stopped.dispatch(this);
                    SoundBoard.playEffect("waypoint");
                } else {
                    x = _point.x, y = _point.y;
                    _ecks.x = _point.x-(4 * _ecks.scaleX), _ecks.y = _point.y-(4 * _ecks.scaleY);
                }    
            }
            if (parent && parent.contains(_trash_closed)) parent.removeChild(_trash_closed);
            if (parent && parent.contains(_trash_open)) parent.removeChild(_trash_open);
        
            if (removed) {
                parent.removeChild(this);
                _point_deleted.dispatch(this);
                puff.emit("puff", evt.stageX, evt.stageY);
            }
        }
    
        private function drawPoint():void {
            var g:Graphics = _ecks.graphics;
            g.beginFill(0, 0);
            g.drawRect(-4, -4, 16, 16);
            g.endFill();
            g.beginFill(0xaa1803);
            g.lineStyle(0, 0xcccccc, 1);
            var cmd:Vector.<int> = new Vector.<int>();
            var path:Vector.<Number> = new Vector.<Number>();
            cmd.push(1,2,2,2,2,2,2,2,2,2,2,2,2);
            path.push(3,0, 5,3, 7,0, 9,3, 7,5, 9,7, 7,9, 5,7, 3,9, 0,7, 3,5, 0,3, 3,0);
            g.drawPath(cmd, path);
            addChild(_ecks);
        }
        public function set point(value:Point):void {
            _point = value;
        }
        public function get point():Point {
            return _point;
        }
    }
}