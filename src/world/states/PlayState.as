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
    import world.Map;
    import ai.spawngrid.SpawnGrid;
    
    import com.gskinner.motion.*;
    import com.gskinner.motion.plugins.*;
    import com.gskinner.motion.easing.*;
    
    public class PlayState extends State {
        private var _map:Map;
        private var _score:int;
        private var _transition:Boolean;
        private var _fort_count:int;
        private var _ship_health:Vector.<int>;
        private var _ships:Vector.<Ship>;
        private var _ships_func:Vector.<Function>;
        
        public function PlayState(transition:Boolean=true):void {
            super();
            _transition = transition;
        }
        
        override public function enter():void {
            startLevel();
            Hud.instance.restartLevel.add(restart);
        }

        override public function exit():void {
            Main.score = Main.currentScore;
            for (var k:int=0; k < Main.TOTAL_SHIPS; k++) {
                if (Main.ships[k] != null) {
                    Main.ships[k].blewUp.remove(_ships_func[k]);
                }
            }
            _ships_func = null;
            _ship_health = null;
            _ships = null;
        }

        private function shipWrapper(i:int):Function {
            var idx:int = i;
            _ships_func[idx] = function(s:Ship):void {
                _ships[idx] = s;
            }
            return _ships_func[idx];
        }

        private function startLevel():void {
            _map = new Map();
            _fort_count = _map.forts.length;
            _ship_health = new Vector.<int>(Main.TOTAL_SHIPS, true);
            _ships = new Vector.<Ship>(Main.TOTAL_SHIPS, true);
            _ships_func = new Vector.<Function>(Main.TOTAL_SHIPS, true);
            _map.complete.addOnce(end);
            for (var i:int=0; i < _map.forts.length; i++) {
                if (_map.forts[i]) _map.forts[i].blewUp.addOnce(fortDestroyed);
            }
            for (var k:int=0; k < Main.TOTAL_SHIPS; k++) {
                if (Main.ships[k] != null) {
                    _ship_health[k] = Main.ships[k].health;
                    Main.ships[k].blewUp.addOnce(shipWrapper(k));
                }
            }
            Main.levelLoaded.addOnce(function():void {
                for (var j:int=0; j < _map.enemy_ships.length; j++) {
                    _map.enemy_ships[j].blewUp.addOnce(removeShip);
                }
            });
            _score = Main.score;
            Main.changeRate(1.5);
            if (_transition) {
                transition(FP.world, _map);
            } else {
                FP.world = _map;
            }
            SoundBoard.playGameTrack();
        }

        override public function restart():void {
            Main.score = _score;
            Main.currentScore = _score;
            Hud.instance.score.text = Hud.commafy(int(Main.currentScore));
            for (var i:int=0; i < Main.TOTAL_SHIPS; i++) {
                if (_ships[i] != null) {
                    Main.ships[i] = _ships[i];
                    Main.ships[i].health = _ship_health[i];
                }
            }
            Hud.instance.modalFadeClear();
            Hud.instance.fadeIn();
            Fog.instance().visible = false;
            Hud.instance.removeLevelComplete();
            startLevel();    
        }

        private function transition(w1:World, w2:World):void {
            var old_buffer:BitmapData = FP.buffer.clone();
            var ripple_grid:SpawnGrid = new SpawnGrid(FP.screen.width, FP.screen.height, 50, 100, false);
            var bmp:Bitmap = new Bitmap(old_buffer);
            var rippler:Rippler = new Rippler(bmp, 60, 6);
            FP.stage.addChildAt(bmp, FP.stage.numChildren);
            FP.world = _map;
            for (var i:int=0; i < ripple_grid.points.length; i++) {
                var p1:Point = ripple_grid.points[i];
                rippler.drawRipple(p1.x, p1.y, Main.random(30, 10), 1);
            }
            Main.levelLoaded.addOnce(function():void {
                new GTween(bmp, 1.5, {'alpha': 0}, {'ease':Linear.easeNone, 'onComplete':function():void {
                    FP.stage.removeChild(bmp);
                    Hud.instance.fadeIn();
                    rippler.destroy();
                    ripple_grid.destroy();
                    ripple_grid = null;
                }});
            });
        }
        
        private function end(status:Boolean):void {
            Fog.instance().fadeOut();
            Hud.instance.showLevelComplete(status);
        }
        
        private function removeShip(ship:Entity):void {
            trace("remove ship called", ship.toString());
            var score:Object = {'value':Main.currentScore};
            new GTween(score, .3, {'value':Main.currentScore+Main.level.ship_worth}, {'ease':Linear.easeNone, 'onChange':function(t:GTween):void {
                Hud.instance.score.text = Hud.commafy(int(score.value));
            }});
            Main.currentScore += Main.level.ship_worth
            Service.logLevelEvent("Enemy Ships Destroyed", Main.level.number);
        }
        
        private function fortDestroyed(fort:Entity):void {
            var score:Object = {'value':Main.currentScore};
            new GTween(score, .3, {'value':Main.currentScore+Main.level.fort_worth}, {'ease':Linear.easeNone, 'onChange':function(t:GTween):void {
                Hud.instance.score.text = Hud.commafy(int(score.value));
            }});
            Main.currentScore += Main.level.fort_worth
            Service.logLevelEvent("Forts Destroyed", Main.level.number);
        }
    }
}