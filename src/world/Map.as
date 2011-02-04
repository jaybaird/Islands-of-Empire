package world {
    import flash.geom.*;
    import flash.utils.*;
    import flash.events.*;
    import flash.display.*;
    import flash.filters.*;
    
    import net.flashpunk.*;
    import net.flashpunk.utils.*;
    import net.flashpunk.graphics.*;
    import net.flashpunk.tweens.misc.Alarm;
    import net.flashpunk.tweens.motion.LinearMotion;

    import org.osflash.signals.Signal;
    
    import gfx.*;
    import util.*;
    import effects.*;
    import components.*;
    import levels.Level;
    import ai.data.*;
    import ai.pather.*;
    import ai.spawngrid.*;
    import world.states.*;
    import world.entities.*;
    import world.entities.layers.*;
    
    public class Map extends BaseMap {
        [Embed(source='/assets/masks/pin.png')] private const FLAG:Class;
        public static const PLANNING_MODE:int = 1;
        public static const PLAYING_MODE:int = 3;
        
        private var _mode:int;
        
        private var _forts:Vector.<Fort>;
        private var _enemy_ships:Vector.<EnemyShip>;
        private var _path:Vector.<Point>;
        
        private var _ships_launched:int;
        private var _current_ship:int;
        
        private var _hud:Hud;
        private var _level:Object;
        private var _flagship:Ship;
        private var _pathfinder:Pathfinder;
        
        private var _point_added:Signal;
        private var _complete_signal:Signal;
        private var _game_started:Signal;
        private var _last_ship_launched:Signal;
        private var _tick:Tween;
        private var _completion_check:Tween;

        private var _ship_buckets:Dictionary;
        private var _blackboard:Blackboard;
        private var _inactivity_timer:Tween;
        
        private var _ship_spawn:SpawnGrid;
        private var _treasure_spawn:SpawnGrid;
        
        private var _extraction_zone:Zone;
        private var _hero_exiting:Boolean;
        private var _hero_message_sent:Boolean;
        private var _active_ships:int;
        
        // tutorial event hooks wheeeeee!
        public var waypointAdded:Signal;
        public var shipSighted:Signal;
        public var fortSighted:Signal;
        public var shipDamaged:Signal;
        public var fortExplode:Signal;
        public var heroDeployed:Signal;
        public var moveCommand:Signal;
        public var pathCompleteSignal:Signal;
        public var doCheckInput:Boolean;
        
        private var _tutorial:Tutorial;
        
        public function Map():void {
            super(Main.level.seed);
            init();
            _mode = PLANNING_MODE;
            _level = Main.level;

            _forts = new Vector.<Fort>();
            _enemy_ships = new Vector.<EnemyShip>();
            _path = new Vector.<Point>();
            _complete_signal = new Signal(Boolean);
            pathCompleteSignal = new Signal();
            _last_ship_launched = new Signal();
            _game_started = new Signal();
            _hud = Hud.instance;
            _blackboard = new Blackboard();
            _inactivity_timer = addTween(new Alarm(_level.inactivity_timer, spawnEnemyShips, Tween.ONESHOT), false);
            createEffects();
            createForts();
            moveCommand = new Signal(Point);
        }
        
        private function createEffects():void {
            add(new Smoke());
            add(new Splash());
            add(new CannonSmoke());
            add(new Explosion());
            add(new Puff());
        }
        
        private function loadTutorial():void {
            if (_tutorial != null) {
                _tutorial.clear();
                _tutorial.reset();
                _tutorial = null;
            }
            waypointAdded = Hud.instance.pathLayer.waypointAdded;
            shipSighted = new Signal(Ship);
            fortSighted = new Signal(Fort);
            shipDamaged = new Signal(Ship);
            fortExplode = new Signal(Fort);
            heroDeployed = new Signal(Ship);
            trace("loading tutorial");
            _tutorial = new Tutorial(this);
        }
        
        override public function begin():void {
            // XXX
            //_complete_signal.dispatch(true);
            _pathfinder = new Pathfinder();
            Pathfinder.init(this, true);
            _ship_spawn = new SpawnGrid(FP.screen.width, FP.screen.height, 50, 100);
            _treasure_spawn = new SpawnGrid(FP.screen.width, FP.screen.height, 50, 100);
            var ships:Vector.<Ship> = Main.ships;
            for (var i:int=1; i < Main.TOTAL_SHIPS; i++) {
                if (ships[i] == null) continue;
                ships[i].x = _level.start.x, ships[i].y = _level.start.y;
                ships[i].fired.removeAll();
                ships[i].fired.add(function():void {
                    (_inactivity_timer as Alarm).reset(_level.inactivity_timer);
                });
            }
            _active_ships = Main.activeShips;
            _last_ship_launched.addOnce(function():void {
                for (i=1; i < Main.TOTAL_SHIPS; i++) {
                    if (ships[i]) ships[i].fired.removeAll();
                }
            });
            addTween(new Alarm(.5, checkPositions, Tween.LOOPING), true);
            Hud.instance.addPathLayer();
            Hud.instance.pathLayer.messaging.add(pathMessage);
            if (_level.number == 1) loadTutorial();
            if (_tutorial) {
                _forts[15].destroyed = true;
                remove(_forts[15]);
                Main.ships[0].arrived.addOnce(function(s:Ship):void {
                    trace("Hero ship deployed.");
                    heroDeployed.dispatch(Main.ships[0]);
                });
            }
            var crate:Crate;
            if (_level.number == 1) {
                crate = new Crate(0, 0);
                crate.x = _level.end.x - 75, crate.y = _level.end.y;
                add(crate);
            } else {
                var idx:int;
                var treasure_point:Point;
                var num_crates:int = Main.random(4, 1);
                for (var j:int=0; j < num_crates; j++) {
                    idx = Main.random(_treasure_spawn.points.length-1);
                    treasure_point = _treasure_spawn.points[idx];
                    crate = new Crate(treasure_point.x, treasure_point.y);
                    add(crate);
                    _treasure_spawn.points.splice(idx, 1);
                }    
            }
            add(crate);
            createEnemyShips();
            Main.levelLoaded.dispatch();
            doCheckInput = true;
            if (_level.number != 1) Hud.instance.showMessage("Create a path from the entry point to the white extraction zone on the right.");
            // XXX 
            //Hud.instance.removePathLayer();
        }
        
        override public function end():void {
            clearTutorial();
        }
        
        public function clearTutorial():void {
            trace("[MAP] clearing tutorial");
            if (_tutorial != null) {
                _tutorial.clear();
            }
            _tutorial = null;
            doCheckInput = true;
        }
        
        private function checkPositions():void {
            for each(var f:Fort in _forts) {
                var e:Ship = FP.world.nearestToEntity("ship", f, true) as Ship;
                if (e && !f.destroyed && f.distanceFrom(e, true) < e.sightDistance) {
                    f.visible = true;
                    if (fortSighted) fortSighted.dispatch(f);
                }
            }
            for each(var es:EnemyShip in _enemy_ships) {
                var s:Ship = FP.world.nearestToEntity("ship", es, true) as Ship;
                if (s && es.distanceFrom(s, true) < s.sightDistance) {
                    es.visible = true;
                    if (shipSighted) shipSighted.dispatch(es);
                } else {
                    es.visible = es.hard_visible ? true : false;
                }
            }
        }
        
        public function tutorialSkipped():void {
            Service.logCustom("Tutorial Skipped");
            for (var i:int=0; i < _enemy_ships.length; i++) {
                _enemy_ships[i].setState("patrol");
            }
            clearTutorial();
        }
                
        public function set enemy_ships(value:Vector.<EnemyShip>):void { _enemy_ships = value; }
        public function get enemy_ships():Vector.<EnemyShip> { return _enemy_ships; }
        
        public function set forts(value:Vector.<Fort>):void { _forts = value; }
        public function get forts():Vector.<Fort> { return _forts; }
        
        public function get complete():Signal { return _complete_signal; }
        public function get started():Signal { return _game_started; }
        
        public function get path():Vector.<Point> { return _path; }
        public function set mode(value:int):void { _mode = value; }
        
        public function get pathfinder():Pathfinder { return new Pathfinder(); }
        public function get shipSpawn():SpawnGrid { return _ship_spawn; }
        public function get blackboard():Blackboard { return _blackboard; }
    
        public function start():void {
            _mode = PLAYING_MODE;
            _game_started.dispatch();
            Hud.instance.removePathLayer();
            add(new Entity(0, 0, new Stamp(Hud.instance.pathImage)));
            Fog.instance().fadeIn();
            _extraction_zone = new Zone(_level.end.x, _level.end.y);
            _extraction_zone.layer = -1;
            add(_extraction_zone);
            tick();
            _tick = addTween(new Alarm(5, tick, Tween.LOOPING), true);
            _inactivity_timer.start();
        }

        private function removeFort(f:Fort):void {
            remove(f);
            Hud.instance.scoreText(f, Main.level.fort_worth);
            if (fortExplode) fortExplode.dispatch(f);
            f = null;
        }
        
        override public function update():void {
            super.update();
            if (_mode != PLAYING_MODE) return;
            if (Main.hero && Main.hero.collideWith(_extraction_zone, Main.hero.x, Main.hero.y)) {
                _hero_exiting = true;
                var p:Vector.<Point> = Hud.instance.pathLayer.path;
                Main.hero.moveTo(Vector.<Point>([p[p.length-1]]));
            }
            if (doCheckInput) checkInput();
        }
        
        private function tick():void {
            if (_ships_launched < _active_ships) {
                var s:Ship = Main.ships[_current_ship];
                while (s == null) {
                    _current_ship++;
                    s = Main.ships[_current_ship];
                }
                s.x = _level.start.x, s.y = _level.start.y;
                if (_current_ship == 0) {
                    var y_offset:int = -32;
                    if (_level.start.y-32 < 50) {
                        y_offset = 32;
                    }
                    (s as Airship).moveTo(Vector.<Point>([new Point(_level.start.x+32, _level.start.y+y_offset)]));
                } else { 
                    s.moveTo(Hud.instance.pathLayer.path);
                }
                s.visible = true;
                add(s);
                _ships_launched++;
                _current_ship++;
                trace("Ships launched:", _ships_launched);
            } else {
                _last_ship_launched.dispatch();
            }
            checkForCompletion();
        }
        
        private function aliveCheck():Boolean {
            for (var i:int=0; i < Main.TOTAL_SHIPS; i++) {
                if (Main.ships[i] != null) return true;
            }
            return false;
        }
        
        private function onscreenCheck():Boolean {
            for (var i:int=1; i < Main.TOTAL_SHIPS; i++) {
                if (Main.ships[i] && Main.ships[i].x < FP.screen.width + 10) return true;
            }
            if (Main.hero && Main.hero.x < FP.screen.width + 10) {
                if (!_hero_message_sent) {
                    _hero_message_sent = true;
                    Hud.instance.showMessage("Get your flagship to the Extraction Zone! You must escape!", 600, 0);
                }
                return true;
            }
            return false;
        }
        
        private function checkForCompletion():void {
            // Round Ending Conditions
            //  1. All player ships are dead.
            //  2. All ships are offscreen
            //  3. All forts are dead
            if (!aliveCheck() || !onscreenCheck()) {
                removeTween(_tick);
                trace("end signal is firing...");
                doCheckInput = false;
                _complete_signal.dispatch(aliveCheck());
            }
        }
        
        private function createEnemyShip(loc:Point, movable:Boolean=false):EnemyShip {
            var enemy_ship:EnemyShip = new EnemyShip(this);
            //enemy_ship.hard_visible = true;
            if (!movable) enemy_ship.setState("hold");
            enemy_ship.x = loc.x, enemy_ship.y = loc.y;
            enemy_ship.blewUp.addOnce(removeEnemyShip);
            _enemy_ships.push(enemy_ship);
            add(enemy_ship);
            return enemy_ship;
        }
        
        private function createEnemyShips():void {
            trace("[MAP] placing enemy ships");
            spawnEnemyShips();
        }
        
        private function getValidSpawnPoints():Vector.<Point> {
            return _ship_spawn.points.filter(function(item:Point, index:int, vector:Vector.<Point>):Boolean {
                var ship:Ship;
                for (var i:int=0; i < Main.TOTAL_SHIPS; i++) {
                    ship = Main.ships[i];
                    if (ship == null) continue;
                    if (Point.distance(ship.point, item) < ship.sightDistance) {
                        return false;
                    }
                }
                return true;
            });
        }
        
        private function spawnEnemyShips():void {
            var points:Vector.<Point> = getValidSpawnPoints();
            var ships_to_spawn:int = _level.enemy_ships;
            while (ships_to_spawn > 0) {
                var spawn_point:Point = points[Main.random(points.length-1)];
                createEnemyShip(spawn_point, true);
                ships_to_spawn--;
            }
        }
        
        private function removeEnemyShip(s:Ship):void {
            remove(s);
            Hud.instance.scoreText(s, Main.level.ship_worth);
            s = null;
        }
        
        private function pathMessage(message:int):void {
            switch(message) {
                case PathLayer.PATH_COMPLETE:
                    pathComplete();
                break;
            }
        }
        
        public function pathComplete():void {
            pathCompleteSignal.dispatch();
            Hud.instance.showPathConfirmDialog(function():void {
                var path_length:int = Hud.instance.pathLayer.path.length;
                var last_point:Point = Hud.instance.pathLayer.path[path_length-1];
                Hud.instance.pathLayer.path.push(new Point(last_point.x+100, last_point.y));
                start();
            }, null); 
        }

        private function checkInput():void {
            FP.point.x = FP.world.mouseX, FP.point.y = FP.world.mouseY;
            if (Input.mouseReleased && !Hud.instance.speedPanel.hitTestPoint(FP.point.x, FP.point.y, true)) {
                if (Main.hero) doHeroAttack(FP.point.clone());
            }
        }
        
        private function doHeroAttack(p:Point):void {
            var entity:Entity;
            for (var i:int=0; i < Main.hero.targets.length; i++) {
                entity = collidePoint(Main.hero.targets[i], p.x, p.y);
                if (entity) break;
            }
            if (entity) {
                Main.hero.setTarget(entity);
                if (!Main.hero.distanceFrom(entity) <= Main.hero.range) {
                    var p1:Point = new Point(entity.x, entity.y);
                    var p2:Point = p1.subtract( Main.hero.point );
                    var len:Number = 1 - (Main.hero.range / p2.length);
                    p2.x *= len, p2.y *= len;
                    p2 = p2.add(Main.hero.point);

                    Main.hero.moveTo(Vector.<Point>([p2]));
                }
            } else {
                moveCommand.dispatch(p);
                Main.hero.moveTo(Vector.<Point>([p]));
            }
        }
        
        private function checkFort(f:Fort):Boolean {
            // add check for on screen fort
            var fp:Point = new Point();
            for (var i:int=0; i < _forts.length; i++) {
                fp.x = f.x, fp.y = f.y;
                if ((fp.x < 25 || fp.x > FP.width-25) || (fp.y < 25 || fp.y > FP.height-25) ||
                    (f.distanceFrom(_forts[i], true) < 25) ||
                    (Point.distance(fp, Main.level.start) < 200)) return false;
            }
            return true;
        }
        
        private function createForts():void {
            trace("[MAP] placing forts");
            var num_forts:int = _level.forts;
            var num_islands:int = _islands.length;
            var runs:int = 0;
            if (num_islands == 0) return;
            
            for (var i:int=0; i < num_forts;) {
                for (var j:int=0; j < num_islands; j++) {
                    var island:Island = _islands[j];
                    var perimeter:Vector.<Point> = island.perimeter;
                    var p:Point = perimeter[int(perimeter.length * FP.random)];
                    var fort:Fort = new Fort(island.x + p.x, island.y + p.y);
                    if (checkFort(fort)) {
                        add(fort);
                        fort.blewUp.addOnce(removeFort);
                        _forts.push(fort);
                        i++;
                    }
                }
                runs++;
                if (runs >= 200) break;
            }
        } 
    }
}