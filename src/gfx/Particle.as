package gfx {
	public class Particle {
		//Particle explosion point X
		public var px:Number;
		//Particle explosion point Y
		public var py:Number;
		//Particle movement X
		public var vx:Number;
		//Particle movement Y
		public var vy:Number;
		//Particle start point X
		public var sx:Number;
		//Particle start point Y
		public var sy:Number;
		//Particle color
		public var pColor:uint;
		//check to explode or move the rocket
		public var explode:int;
		//Random glowing particles
		public var glowParticle:int;
		//Speed of the Launch.
		public var lSpeed:int;

		public function Particle() {
			this.px = 0;
			this.py = 0;
			this.vx = 0;
			this.vy = 0;
			this.sx = 0;
			this.sy = 0;
			this.explode = 0;
			this.glowParticle = 0;
			this.pColor = 0xFFFFFFFF;
			this.lSpeed = 0;
		}
	}
}