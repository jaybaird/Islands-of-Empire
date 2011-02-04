package components {
    import flash.utils.*;
    import flash.events.*;
    import flash.display.*;
    
    import com.bit101.components.*;
    
    import gfx.Hud;
    import world.entities.Ship;
    
    public class MessageWindow extends RoundedPanel {
        private var _ecks:Sprite;
        private var _text:Text;
        private var _time_added:int;
        private var _priority:int;
        
        public function MessageWindow(p:DisplayObjectContainer, x:int, y:int, priority:int=1):void {
            super(p, x, y);
            height = 40;
            alpha = .85;
            _text = new Text(this, 0, 5, "");
            _text.selectable = _text.editable = false;
            _ecks = new Sprite();
            _ecks.scaleX = _ecks.scaleY = 1;
            _ecks.x = 10, _ecks.y = 10;
            drawEcks();
            _ecks.buttonMode = true, _ecks.useHandCursor = true;
            _ecks.addEventListener(MouseEvent.CLICK, mouseClick);
            _time_added = getTimer();
            _priority = priority;
        }
        
        private function mouseClick(evt:MouseEvent):void {
            _ecks.removeEventListener(MouseEvent.CLICK, mouseClick);
            Hud.instance.removeMessage(this);
        }
        
        private function drawEcks():void {
            var g:Graphics = _ecks.graphics;
            g.beginFill(0xcccccc);
            g.lineStyle(0, 0xcccccc, 1);
            var cmd:Vector.<int> = new Vector.<int>();
            var path:Vector.<Number> = new Vector.<Number>();
            cmd.push(1,2,2,2,2,2,2,2,2,2,2,2,2);
            path.push(3,0, 5,3, 7,0, 9,3, 7,5, 9,7, 7,9, 5,7, 3,9, 0,7, 3,5, 0,3, 3,0);
            g.drawPath(cmd, path);
            g.endFill();
            addChild(_ecks);
        }
        
        public function get priority():int { return _priority; }
        public function get timeAdded():int { return _time_added; }
        
        public function set message(s:String):void {
            _text.text = s;
            width = _text.width + 10;
            _text.x = width/2 - (_text.width/2 - 15);   
        }
    }
}