package effects {
    import net.flashpunk.Entity;
    import net.flashpunk.graphics.Emitter;
    import net.flashpunk.graphics.ParticleType;
    import net.flashpunk.utils.Ease;
    
    public class Smoke extends Entity {
        [Embed(source='/assets/sprites/damage_smoke.png')] private const SMOKE:Class;
        public var emitter:Emitter;
        
        public function Smoke():void {
            emitter = new Emitter(SMOKE, 12, 12);
            graphic = emitter;
            emitter.x = -13;
            emitter.y = -16;
            
            var p:ParticleType = emitter.newType("smoke", [0, 1, 2, 3, 4]);
            p.setMotion(20, 5, 4, 140, 15, 2, Ease.cubeOut);
            p.setAlpha(1, 0);
        }
    }
}