package world.entities {
    import flash.geom.Point;
    
    import net.flashpunk.*;
    import org.osflash.signals.Signal;
    import net.flashpunk.graphics.Spritemap;
    
    import gfx.ShipHud;
    import util.ds.Vector2D;
    
    public class Airship extends Ship {
        [Embed(source="/assets/sprites/airship_frames.png")]  public static const AIRSHIP:Class;
        [Embed(source="/assets/sprites/airship_frames_damage_2.png")]  public static const AIRSHIP_DAMAGE2:Class;
        [Embed(source="/assets/sprites/airship_frames_damage_3.png")]  public static const AIRSHIP_DAMAGE3:Class;
        [Embed(source="/assets/sprites/airship_frames_damage_4.png")]  public static const AIRSHIP_DAMAGE4:Class;
        public static var TOTAL_HEALTH:int;
        public static var WIDTH:int;
        {
            TOTAL_HEALTH = 800;
            WIDTH = 32;
            PATH_THRESHOLD = 5;
        }
        
        public function Airship(name:String):void {
            super(name);
            createSpritemaps();
            graphic = _spritemaps[0];
            type = "ship";
            setHitbox(WIDTH, WIDTH, 16, 24);
            rateOfFire = 2.0;
            range = 60;
            targets = ['fort', 'enemyship'];
            health = TOTAL_HEALTH;
            _sight_range = 90;
            _hud = new ShipHud(this);
            _hud.update(_health);
            createFogMask();
        }
        
        override protected function createSpritemaps():void {
            _spritemaps = new Vector.<Spritemap>();
            var sprites:Vector.<Class> = Vector.<Class>([AIRSHIP, AIRSHIP_DAMAGE2, AIRSHIP_DAMAGE3, AIRSHIP_DAMAGE4]);
            for (var i:int=0; i < sprites.length; i++) {
                var sprite:Spritemap = new Spritemap(sprites[i], 32, 32);
                sprite.smooth = false;
                sprite.add("main", [0, 1, 2], 12);
                sprite.play("main");
                sprite.x = -16;
                sprite.y = -24;
                _spritemaps.push(sprite);
            }
        }
        
        override protected function getStats():String {
            return "\nHP: " + health + "/" + TOTAL_HEALTH + "\nKills: " + _kills + "    Hit %: " + int(_hit_rate * 100) + "%\nHits: " + _hits + "    Shots Fired: " + _shots_fired;
        }
        
        override protected function healthUpdated():void {
            if (_health < 350 && _health >= 200) {
                graphic = _spritemaps[1];
            } else if (_health < 200 && _health >= 100) {
                graphic = _spritemaps[2];
            } else if (_health < 100) {
                graphic = _spritemaps[3];
            } else {
                graphic = _spritemaps[0];
            }
            _hud.update(_health);
        }
        
        override protected function checkInput():void {
            _hud.visible = true;
        }
        
        override public function added():void {
            super.added();
            _max_speed = 120;
        }
        
        public function moveToPoint(p:Point):void {
            var vec:Vector2D = new Vector2D(p.x, p.y);
            super.arrive(vec);
        }
    }
}