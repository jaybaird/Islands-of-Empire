package world.states {
    import flash.geom.Point;
    import flash.display.*;
    
    import lib.swfstats.*;
    import net.flashpunk.*;
    import net.flashpunk.graphics.Stamp;
    
    import world.*;
    import util.*;
    import util.fsm.*;
    import world.menu.*;
    import gfx.*;
    import world.entities.*;
    import world.BaseMap;
    import reactor.*;
    
    import com.gskinner.motion.*;
    import com.gskinner.motion.plugins.*;
    import com.gskinner.motion.easing.*;
    
    public class EndState extends State {
        [Embed(source='/assets/splash/endgame.png')] private const ENDGAME:Class;
        private var _map:BaseMap;
        
        public function EndState():void {
            super();
        }
        
        override public function enter():void {
            startLevel();
        }

        override public function exit():void {
            
        }

        private function startLevel():void {
            _map = new BaseMap(0, true);
            _map.init();
            FP.world = _map;
            FP.stage.addChild(new ENDGAME());
            FP.stage.addChild(new Fireworks(FP.width, FP.height));
            Reactor.callLater(function():void {
                 Service.postScore(FP.stage);
            });
        }
    }
}