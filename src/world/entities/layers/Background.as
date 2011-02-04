package world.entities.layers {
    import flash.display.*;
    import flash.utils.ByteArray;
    
    import net.flashpunk.Entity;
    import net.flashpunk.graphics.Image;
    
    public class Background extends Entity {
        [Embed(source="/assets/filters/CreateOcean.pbj", mimeType="application/octet-stream")]
        private static const CREATE_OCEAN:Class;
        
        public function Background(data:BitmapData) {
            super(0, 0, new Image(createOcean(data)));
        }
        
        override public function added():void {
            layer = 2;
        }
        
        private function createOcean(data:BitmapData):BitmapData {
            var shader:Shader = new Shader(new CREATE_OCEAN() as ByteArray);
            var ocean_data:BitmapData = new BitmapData(data.width, data.height, true, 0xff016aad);
            var job:ShaderJob = new ShaderJob(shader, ocean_data);
            shader.data.src.input = data;
            shader.precisionHint = ShaderPrecision.FAST;
            job.start(true);
            return ocean_data;
        }
    }
}