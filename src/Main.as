package {
    import flash.media.*;
    import flash.display.*;
    import flash.events.Event;
    import flash.filters.*;
    
    import net.flashpunk.*;
    import net.flashpunk.utils.Input;
	import net.flashpunk.utils.Key;
    
    import org.osflash.signals.Signal;
    
    import mochi.as3.*;
    
    import ai.pather.Pathfinder;
    import world.*;
    import gfx.*;
    import levels.Level;
    import world.menu.*;
    import world.entities.*;
    import util.*;
    import util.fsm.*;
    import world.states.*;
    import reactor.Reactor;
    
    [Frame(factoryClass="util.Preloader")]
    [SWF(backgroundColor=0, width=800, height=600, frameRate=60)]
    public class Main extends Engine {
        [Embed(source='/assets/splash/loading.png')]
        private static const LOADING:Class;
        
        public static const TOTAL_SHIPS:int = 11;
        public static const MAX_LEVEL:int = 5;
        
        private static var _level:Object;
        private static var _levelState:StateMachine;
        private static var _current_map:BaseMap;
        private static var _ships:Vector.<Ship>;
        private static var _active_ships:int;
        private static var _hero:Airship;

        private static var _level_loaded:Signal;
        private static var _next_level:Signal;
        private static var _rate_changed:Signal;
        private static var _graph_visible:Boolean;
        
        private static var _stats:Stats;
        private static var _current_score:MochiDigits;
        private static var _score:MochiDigits;

        private static var _upgrades:Object;
        private static var _upgrade_prices:Object;
        
        {
            _upgrades = {
                'cannon': false,
                'sails': false,
                'grapeShot': false,
                'armorPlating': false
            };
            _upgrade_prices = {
                'cannon': 9000,
                'sails': 6000,
                'grapeShot': 3000,
                'armorPlating': 15000
            };
        }
        
        public function Main():void {
            super(800, 600, 60, false);
            SoundBoard.init();
            Service.instance.connect();
            
            _level_loaded = new Signal();
            _next_level = new Signal();
            _rate_changed = new Signal(Number);
            _next_level.add(advanceLevel);
            _level = Level.loadLevel(1);
            _active_ships = TOTAL_SHIPS;
            createShips();
            // XXX
            _score = new MochiDigits(0);
            _current_score = new MochiDigits(0);
            FP.volume = 1;
            FP.screen.color = 0;
            _stats = new Stats();
            addChild(Hud.instance);
            Hud.instance.visible = false;
            addEventListener(Event.ADDED, hudBump);
            //Main.score = 50000;
            //Main.currentScore = 50000;
        }

        public static function random(high:int=10, low:int=0):int {
            return int(Math.random() * (1+high-low)) + low;
        }
        
        public static function randomFloat(high:Number=1.0, low:int=0):int {
            return Math.random() * (1+high-low) + low;
        }

        override public function init():void {
            //FP.console.enable()
            _levelState = new StateMachine();
            // XXX
             _levelState.changeState(new SponsorState());
            //_levelState.changeState(new MenuState());
            //startNewGame();
        }

        public static function changeRate(rate:Number):void {
            FP.rate = rate;
            _rate_changed.dispatch(rate);
        }

        override public function update():void {
            // XXX
            //checkInput();
            super.update();
            Reactor.pump();
        }

        private static function loadLevel(lvl:Object, transition:Boolean=true):void {
            _level = lvl;
            if (_level.number == 13) {
                _levelState.setNextState(new EndState());
            } else {
                _levelState.setNextState(new PlayState(transition));
            }
            _levelState.nextState();
        }
        
        private static function createShips():void {
            var i:int = 0;
            _ships = new Vector.<Ship>(TOTAL_SHIPS, true);
            _ships[0] = new Airship('The Aurora');
            _hero = _ships[0] as Airship;
            _ships[0].blewUp.add(function(s:Ship):void {
                removeShip(s);
                heroDied(s); 
            });
            for (i = 1; i < TOTAL_SHIPS; i++) {
                var ship:Ship = new Ship(ShipNames.getShipName());
                ship.blewUp.add(removeShip);
                _ships[i] = ship;
            }
        }
        
        private static function heroDied(e:Entity):void {
            Service.logLevelEvent("Hero Destroyed", _level.number);
            trace("Hero died. This means the game is over :(");
            (FP.world as Map).complete.dispatch(false);
        }
        
        private static function removeShip(e:Entity):void {
            Service.logLevelEvent("Ships Destroyed", _level.number);
            FP.world.remove(e);
            _ships[_ships.indexOf(e)] = null;
            _active_ships--;
        }
        
        private function hudBump(evt:Event):void {
            setChildIndex(Hud.instance, numChildren > 0 ? numChildren - 1 : numChildren);
        }
        
        public static function get upgrades():Object { return _upgrades; }
        public static function upgradeCost(key:String):Number {
            return _upgrade_prices[key];
        }
        public static function get activeShips():int { 
            return _active_ships;
        }
        public static function get rateChanged():Signal { return _rate_changed; }
        public static function get nextLevel():Signal { return _next_level; }
        public static function get levelLoaded():Signal { return _level_loaded; }
        public static function get ships():Vector.<Ship> { return _ships; }
        public static function get hero():Airship { return _ships[0] as Airship; }
        
        public static function get level():Object { return _level; }
        public static function get state():StateMachine { return _levelState; }
        
        public static function set currentScore(value:Number):void { _current_score.value = value; }
        public static function get currentScore():Number { return _current_score.value; }
        public static function set score(value:Number):void { _score.value = value; }
        public static function get score():Number { return _score.value; }
        
        public static function startNewGame():void {
            trace("[MAIN] starting a new game.");
            Service.logPlay(1);
            Service.logCustom("New Game");
            startLevel(1, true);
        }
        
        public static function continueGame():void {
            trace("[MAIN] continuing game in progress.");
            var data:Object = Service.loadSaveData();
            if (data == null) {
                startNewGame();
            } else {
                for (var i:int=0; i < TOTAL_SHIPS; i++) {
                    if (data.health[i] == null) {
                        Main.ships[i] = null;
                    } else {
                        Main.ships[i].health = data.health[i];
                    }
                }
                _upgrades = data.upgrades;
                if (_upgrades.armorPlating) {
                    for (i=0; i < TOTAL_SHIPS; i++) {
                        if (data.health[i] == null) continue;
                        Main.ships[i].totalHealth = FP.getClass(Main.ships[i]).TOTAL_HEALTH + 100;
                        Main.ships[i].health = data.health[i];
                    }
                }
                Main.score = data.score;
                Main.currentScore = data.score;
                Hud.instance.score.text = Hud.commafy(Main.currentScore);
                loadLevel(data.level);
                Service.logCustom("Continue Game", data.level.number);
                Service.logPlay(data.level.number);
            }
        }
        
        private static function advanceLevel():void {
            Service.dumpSaveData();
            Hud.instance.modalFadeClear();
            Hud.instance.removeLevelComplete();
            Hud.instance.fadeIn();
            Hud.instance.visible = true;
            startLevel(_level.number+1);
        }
        
        public static function startLevel(lvl:int, new_game:Boolean=false):void {
            loadLevel(Level.loadLevel(lvl));
        }
    }
}