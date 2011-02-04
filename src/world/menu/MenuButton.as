package world.menu {
    import flash.display.*;
    import flash.events.MouseEvent;
    
    import util.SoundBoard;
    
    public class MenuButton extends Sprite {
        public var callback:Function;
        
        public function MenuButton():void {}
        
        public static function createButton(p:DisplayObjectContainer, x:int, y:int, img:Bitmap, callback:Function):MenuButton {
            var button:MenuButton = new MenuButton();
            button.buttonMode = true, button.useHandCursor = true;
            button.addChild(img);
            button.x = x, button.y = y;
            button.addEventListener(MouseEvent.CLICK, button.checkInput);
            button.callback = callback;
            p.addChild(button);
            return button;
        }
        
        public function checkInput(evt:MouseEvent):void {
            SoundBoard.playEffect("menuClick");
            if (callback != null) callback();
        }
    }
}