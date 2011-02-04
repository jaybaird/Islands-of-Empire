package gfx {
    import flash.display.*;
    
    import net.flashpunk.*;
    
    public class NoiseScreen extends Screen {
        private var _noise:Bitmap;
        
        public function NoiseScreen():void {
            super();
            drawNoise();
            _noise.blendMode = BlendMode.ADD;
            _sprite.addChild(_noise);
            color = 0x103c59;
        }
        
        private function drawNoise():void
        {
            var noise:Shape = new Shape();
            var noiseTexture:BitmapData = new BitmapData(128, 128, true, 0);
            _noise = new Bitmap(new BitmapData(FP.width, FP.height, true, 0));
            noiseTexture.noise(Math.round(Math.random()*65536), 0, 8, 7, true);
            noise.graphics.beginBitmapFill(noiseTexture);
            noise.graphics.drawRect(0, 0, FP.width, FP.height);
            noise.graphics.endFill();
            _noise.bitmapData.draw(noise);
        }
    }
}