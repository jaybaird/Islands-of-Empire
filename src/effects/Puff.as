package effects {
    import net.flashpunk.Entity;
    import net.flashpunk.graphics.Emitter;
    import net.flashpunk.graphics.ParticleType;
    import net.flashpunk.utils.Ease;
    
    public class Puff extends Entity {
        [Embed(source='/assets/sprites/waypoint_puff.png')] private const SMOKE:Class;
        public var emitter:Emitter;
        
        public function Puff():void {
            emitter = new Emitter(SMOKE, 24, 24);
            graphic = emitter;
            emitter.x = -12;
            emitter.y = -12;
            
            var p:ParticleType = emitter.newType("puff", [0, 1, 2, 3, 4]);
            p.setMotion(0, 0, .5);
            p.setAlpha(1, 1);
        }
    }
}