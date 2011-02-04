package effects {
    import net.flashpunk.Entity;
    import net.flashpunk.graphics.Emitter;
    import net.flashpunk.graphics.ParticleType;
    import net.flashpunk.utils.Ease;
    
    public class CannonSmoke extends Entity {
        [Embed(source='/assets/sprites/smoke.png')] private const SMOKE:Class;
        public var emitter:Emitter;
        
        public function CannonSmoke():void {
            emitter = new Emitter(SMOKE, 12, 12);
            graphic = emitter;
            emitter.x = -13;
            emitter.y = -16;
            
            var cannon_smoke:ParticleType = emitter.newType("cannon_smoke", [1,2,3,4]);
            cannon_smoke.setMotion(0, 0, .75);
            cannon_smoke.setAlpha(1, 0);
        }
    }
}