package effects {
    import net.flashpunk.*;
    import net.flashpunk.graphics.Emitter;
    import net.flashpunk.graphics.ParticleType;
    import net.flashpunk.utils.Ease;
    
    public class Splash extends Entity {
        [Embed(source='/assets/sprites/splash_frames.png')] private const SPLASH:Class;
        public var emitter:Emitter;
        
        public function Splash():void {
            emitter = new Emitter(SPLASH, 16, 16);
            emitter.x = -8;
            emitter.y = -16;
            graphic = emitter;
            var p:ParticleType = emitter.newType("splash", [0, 1, 2, 3, 4, 5, 6]);
            p.setMotion(0, 0, .75);
            p.setAlpha(1, 1);
        }
    }
}