package components {
    import flash.display.DisplayObjectContainer;
    import flash.text.TextFormat;
    import flash.text.TextField;
    import flash.text.AntiAliasType;
    import com.bit101.components.Label;
    
    public class FreebooterLabel extends Label {
        private var _size:int;
        
        public function FreebooterLabel(parent:DisplayObjectContainer=null, xpos:Number=0, ypos:Number=0, text:String="", size:int=24):void {
            _size = size;
            super(parent, xpos, ypos, text);
        }
        
        override protected function addChildren():void {
            _height = 18;
            _tf = new TextField();
            _tf.height = _height;
            _tf.embedFonts = true;
            _tf.selectable = false;
            _tf.mouseEnabled = false;
            _tf.antiAliasType = AntiAliasType.ADVANCED;
            //_tf.defaultTextFormat = new TextFormat("Freebooter", _size, 0xFFFFFF);
            _tf.text = _text;           
            addChild(_tf);
            draw();
        }
    }
}