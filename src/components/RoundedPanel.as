package components {
    import flash.display.Sprite;
    import flash.display.*;
    
    import com.bit101.components.*;
    
    public class RoundedPanel extends Panel {
        protected var _radius:Number;
        protected var _alpha:Number;
        protected var _border:Boolean;
        
        public function RoundedPanel(parent:DisplayObjectContainer=null, xpos:Number=0, ypos:Number=0, radius:Number=10, border:Boolean=true):void {
            _radius = radius;
            _alpha = 1.0;
            _border = border;
            super(parent, xpos, ypos);
            cacheAsBitmap = true;
        }
        
        public function set radius(value:int):void {
            _radius = value;
            invalidate();
        }
        
        override public function set alpha(value:Number):void {
            _alpha = value;
            invalidate();
            for (var i:int = 0; i < numChildren; i++) {
                var child:DisplayObject = getChildAt(i);
                if (child.hasOwnProperty('alpha')) {
                    child.alpha = value;
                }
            }
        }
        
        override public function draw():void {
            super.draw();
            _background.graphics.clear();
            if (_border) _background.graphics.lineStyle(1, 0xacacac, 1, true);
            if(_color == -1) {
                _background.graphics.beginFill(0, _alpha);
            } else {
                _background.graphics.beginFill(_color, _alpha);
            }
            _background.graphics.drawRoundRect(0, 0, _width, _height, _radius);
            _background.graphics.endFill();
            
            drawGrid();
            
            _mask.graphics.clear();
            _mask.graphics.beginFill(0xff0000);
            _mask.graphics.drawRoundRect(0, 0, _width, _height, _radius);
            _mask.graphics.endFill();
        }
    }
}