package world.entities {
    import net.flashpunk.FP;
    import net.flashpunk.Tween;
    import net.flashpunk.Entity;
    import net.flashpunk.graphics.Spritemap;
    import net.flashpunk.tweens.motion.LinearMotion;
    
    public class Bird extends Entity {
        [Embed(source='/assets/sprites/bird_frames.png')] private static const BIRDCLIP:Class;
        private var _motion:LinearMotion;
        
        public function Bird():void {
            super(0, 0);
            var sprite:Spritemap = new Spritemap(BIRDCLIP, 8, 7);
            collidable = false;
            sprite.smooth = true;
            sprite.add("main", [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11], 24);
            sprite.play("main");
            sprite.x = -4, sprite.y = -3;
            graphic = sprite;
            
            _motion = new LinearMotion(recycle);
            addTween(_motion, false);
        }
        
        private function recycle():void {
            FP.world.recycle(this);
        }
        
        override public function added():void {
            var drift_y:int = Main.random(y+50, y-50);
            _motion.setMotion(x, y, FP.screen.width+5, drift_y, Main.random(20, 10));
        }
        
        override public function update():void {
            super.update();
            x = _motion.x, y = _motion.y; 
        }
    }
}