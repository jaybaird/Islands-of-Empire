package components {
    import flash.filters.*;
    import flash.events.MouseEvent;
    import flash.display.Bitmap;
    import flash.display.SimpleButton;
    
    import net.flashpunk.utils.Input;
    
    public class ToggleButton extends SimpleButton {
        private static const _selected:GlowFilter = new GlowFilter(0x00FF00, 1.0, 2.0, 2.0, 2);
        private var _toggled:Boolean;
        private var _default_state:Bitmap;
        private var _on_state:Bitmap;
        private var _func:Function;
        
        public function ToggleButton(default_state:Bitmap, on_state:Bitmap, func:Function=null):void {
            useHandCursor = true;
            upState = overState = hitTestState = downState = default_state;
            _default_state = default_state;
            _func = func;
            if(on_state == null) {
                _on_state = _default_state;
            } else {
                _on_state = on_state;
            }
            addEventListener(MouseEvent.CLICK, mouseClick);
        }
        
        private function mouseClick(evt:MouseEvent):void {
            evt.stopImmediatePropagation();
            toggled = !toggled;
            if (_toggled) {
                upState = overState = hitTestState = downState = _on_state;
                filters = [_selected];
            } else {
                upState = overState = hitTestState = downState = _default_state;
                filters = null;
            }
            if (_func != null) _func();
            Input.mouseReleased = false;
        }
        
        public function set toggled(value:Boolean):void {
            _toggled = value;
            if (value) {
                upState = overState = hitTestState = downState = _on_state;
                filters = [_selected];
            } else {
                upState = overState = hitTestState = downState = _default_state;
                filters = null;
            }
        }
        public function get toggled():Boolean { return _toggled; }
    }
}