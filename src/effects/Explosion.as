package effects {
    import net.flashpunk.Entity;
    import net.flashpunk.graphics.Emitter;
    import net.flashpunk.graphics.ParticleType;
    import net.flashpunk.utils.Ease;
    
    public class Explosion extends Entity {
        [Embed(source='/assets/sprites/explosion.png')] private const EXPLOSION:Class;
        public var emitter:Emitter;
        
        public function Explosion():void {
            emitter = new Emitter(EXPLOSION, 32, 32);
            graphic = emitter;
            emitter.x = -16;
            emitter.y = -16;
            
            var p:ParticleType = emitter.newType("explosion", [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10]);
            p.setMotion(0, 0, 1);
        }
    }
}