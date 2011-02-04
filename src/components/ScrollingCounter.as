package components {
    import flash.events.Event;
    import flash.display.Shape;
    import flash.display.Sprite;
    import flash.display.Bitmap;
    import flash.display.PixelSnapping;
    import flash.display.BitmapData;
    
    import com.gskinner.motion.*;
    import com.gskinner.motion.plugins.*;
    import com.gskinner.motion.easing.*;
    
    public class ScrollingCounter extends Sprite {
        [Embed(source="/assets/fonts/small_numbers.png")] public static const NUMBERS:Class;
        private var _number:int;
        private var _color:uint;
        private var _number_bmp:BitmapData;
        private var _digit_height:int;
        private var _display:Vector.<Bitmap>;
        private var _tweens:Vector.<GTween>;
        private var _init:Boolean;
        
        public function ScrollingCounter(num:int=0, color:uint=0xff000000, big:Boolean=false):void {
            _number = num;
            _color = color;
            _display = new Vector.<Bitmap>(10, true);
            _tweens = new Vector.<GTween>(10, true);
            _number_bmp = new NUMBERS().bitmapData;
            _digit_height = 8;
            if (_color != 0xff000000) {
                _number_bmp.threshold(_number_bmp, _number_bmp.rect, _number_bmp.rect.topLeft, "==", 0xff000000, _color, 0xff000000);
            }
            addEventListener(Event.ADDED_TO_STAGE, init);
        }
        
        private function init(evt:Event):void {
            removeEventListener(Event.ADDED_TO_STAGE, init);
            var i:int = 0;
            for (i=0; i < _display.length; i++) {
                _display[i] = new Bitmap(_number_bmp.clone(), PixelSnapping.AUTO, false);
                _display[i].x = (_number_bmp.width-1) * i;
                _tweens[i] = new GTween(_display[i], .3);
                addChild(_display[i]);
            }
            var _mask:Shape = addChild(new Shape()) as Shape;
            _mask.graphics.beginFill(0xffffff, 0);
            _mask.graphics.drawRect(0, 0, (_number_bmp.width-1) * 10, _digit_height);
            mask = _mask;
            _init = true;
            render();
        }
        
        public function get number():int { return _number; }
        public function set number(value:int):void { 
            _number = value; 
            if (_init) render();
        }
        
        private function render(direction:int=0):void {
            var i:int = 0;
            var digits:Vector.<int> = getDigits();
            for(i=0; i < digits.length; i++) {
                _tweens[i].setValue("y", int(-1 * (digits[i] * _digit_height)));
                _tweens[i].ease = Linear.easeNone;
            }
            for(i=digits.length; i < _display.length; i++) {
                _display[i].y = int(_digit_height);
            }
        }

        public function increment():void { number += 1; }
        public function decrement():void { number -= 1; }
    
        private function getDigits():Vector.<int> {
            var parts:Vector.<int> = new Vector.<int>();
            var tmp:int = _number;
            if (tmp == 0) {
                parts.push(0);
                return parts;
            } else {
                while(tmp != 0) {
                    parts.push(tmp % 10);
                    tmp = tmp / 10;
                }
            }
            return parts.reverse();
        }
    }
}