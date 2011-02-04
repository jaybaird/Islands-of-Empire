package world.states {
    import flash.net.*;
    import flash.events.*;
    import flash.utils.Timer;
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
    
    public class SplashState extends State {
        [Embed(source='/assets/splash/steam_harmonics.png')] private const TITLE_SCREEN:Class;
        
        private var _sprite:Sprite;
        
        public function SplashState():void {}
        
        override public function enter():void {
            _sprite = new Sprite();
            _sprite.buttonMode = true, _sprite.useHandCursor = true;
            _sprite.addEventListener(Event.ADDED_TO_STAGE, init);
             var bmp:Bitmap = new TITLE_SCREEN();
            _sprite.addChild(bmp);
            FP.stage.addChild(_sprite);
        }
    
        private function init(evt:Event):void {
            _sprite.removeEventListener(Event.ADDED_TO_STAGE, init);
            new GTween(_sprite, 3.5, {}, {'ease':Linear.easeNone, 'onComplete': function():void {
                new GTween(_sprite, .5, {'alpha':0}, {'ease':Linear.easeNone, 'onComplete': function():void {
                    FP.stage.removeChild(_sprite);
                    Main.state.nextState();
                }});
            }});
            Main.state.setNextState(new MenuState());
            _sprite.addEventListener(MouseEvent.CLICK, splashClick);
        }
    
        private function splashClick(evt:MouseEvent):void {
            var url:URLRequest = new URLRequest("http://www.steamharmonics.com/");
            navigateToURL(url, "_blank");
        }
    
        override public function exit():void {
            FP.screen.color = 0x103c59;
            _sprite.removeEventListener(MouseEvent.CLICK, splashClick);
        }
    }
}