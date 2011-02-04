package world.states {
    import flash.net.*;
    import flash.events.*;
    import flash.utils.*;
    import flash.display.*;
    
    import lib.swfstats.*;
    import net.flashpunk.*;
    import net.flashpunk.graphics.*;
    
    import gfx.*;
    import util.*;
    import util.fsm.*;
    import world.*;
    import world.menu.*;
    
    import com.gskinner.motion.*;
    import com.gskinner.motion.plugins.*;
    import com.gskinner.motion.easing.*;
    
    public class SponsorState extends State {
        [Embed(source='/assets/splash/armor_intro.swf')] private const ARMOR_INTRO:Class;
        
        private var _sprite:Sprite;
        private var _intro:MovieClip;
        private var _binary:ByteArray;
        
        public function SponsorState():void {}
        
        override public function enter():void {
            _sprite = new Sprite();
            _sprite.graphics.beginFill(1, 0);
            _sprite.graphics.drawRect(0, 0, FP.width, FP.height);
            _intro = new ARMOR_INTRO();
            _sprite.buttonMode = true, _sprite.useHandCursor = true;
            _sprite.addEventListener(Event.ADDED_TO_STAGE, init);
            _sprite.addChild(_intro);
            _intro.x = FP.width/2 - _intro.width/2, _intro.y = FP.height/2 - _intro.height/2;
            FP.stage.addChild(_sprite);
        }
    
        private function init(evt:Event):void {
            _sprite.removeEventListener(Event.ADDED_TO_STAGE, init);
            new GTween(_sprite, 5, {}, {'ease':Linear.easeNone, 'onComplete': function():void {
                FP.stage.removeChild(_sprite);
                Main.state.nextState();
            }});
            Main.state.setNextState(new MenuState());
            _sprite.addEventListener(MouseEvent.CLICK, splashClick);
        }
    
        private function splashClick(evt:MouseEvent):void {
            var url:URLRequest = new URLRequest("http://www.armorgames.com/");
            navigateToURL(url, "_blank");
        }
    
        override public function exit():void {
            FP.screen.color = 0x103c59;
            _sprite.removeEventListener(MouseEvent.CLICK, splashClick);
        }
    }
}