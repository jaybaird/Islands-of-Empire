package world.entities {
    import flash.display.Bitmap;
    
    import net.flashpunk.*;
    import net.flashpunk.graphics.Spritemap;
    
    import com.gskinner.motion.*;
    import com.gskinner.motion.plugins.*;
    import com.gskinner.motion.easing.*;
    
    import gfx.Hud;
    import util.Service;
    
    public class Crate extends Entity {
        [Embed(source='/assets/sprites/crate.png')] public static const CRATE:Class;
        
        public function Crate(x:int, y:int):void {
            trace("crate placed at", x, y);
            var sprite:Spritemap = new Spritemap(CRATE, 13, 11);
            sprite.smooth = false;
            sprite.add("main", [0, 1, 2, 3], 2);
            sprite.play("main");
            sprite.x = -7;
            sprite.y = -5;
            this.x = x, this.y = y;
            graphic = sprite;
            setHitbox(13, 11, 7, 5);
        }
        
        override public function update():void {
            for (var i:int=0; i < Main.ships.length; i++) {
                if (collideWith(Main.ships[i], x, y)) {
                    trace("hit crate.");
                    var score:Object = {'value':Main.currentScore};
                    var value:int = Main.random(3, 10);
                    Hud.instance.scoreText(this, (value * 100));
                    new GTween(score, .3, {'value':Main.currentScore+(value * 100)}, {'ease':Linear.easeNone, 'onChange':function(t:GTween):void {
                        Hud.instance.score.text = Hud.commafy(int(score.value));
                    }});
                    Main.currentScore += (value * 100);
                    Service.logLevelEvent("Crates Recovered", Main.level.number);
                    FP.world.remove(this);
                    break;
                }
            }
        }
    }
}