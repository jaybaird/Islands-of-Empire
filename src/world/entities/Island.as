package world.entities {
    import flash.geom.*;
    import flash.utils.*;
    import flash.events.*;
    import flash.filters.*;
    import flash.display.*;

    import net.flashpunk.*;
    import net.flashpunk.graphics.Image;
    import net.flashpunk.masks.Pixelmask;
    
    import util.MapUtils;

    public class Island extends Entity {
        [Embed(source="/assets/filters/CreateIsland.pbj", mimeType="application/octet-stream")] 
        private static const CREATE_ISLAND:Class;
        private static var ISLAND_STYLE_FILTER:GlowFilter;
        private static var ISLAND_OUTLINE_FILTER:GlowFilter;
        private static var _shader:Shader;
        
        private var _perimeter:Vector.<Point>;
        private var _rect:Rectangle; 
        private var _image:Image;
        private var _area:int;
        
        {
            _shader = new Shader(new CREATE_ISLAND() as ByteArray);
            _shader.precisionHint = ShaderPrecision.FAST;
            ISLAND_STYLE_FILTER = new GlowFilter(0x212121, .8, 1, 1, 5, BitmapFilterQuality.HIGH, true, false);
            ISLAND_OUTLINE_FILTER = new GlowFilter(0x9a9a9a, 1, 2, 2, 10, BitmapFilterQuality.HIGH, false, false);
        }
        
        public function Island(r:Rectangle, mask_pixels:Vector.<uint>, noise_pixels:Vector.<uint>):void {
            super();
            var island:BitmapData = createBitmapData(r, mask_pixels, noise_pixels);
            var island_copy:BitmapData = new BitmapData(r.width+8, r.height+8, true, 0);
            island_copy.copyPixels(island, island.rect, new Point(4, 4));
            island = island_copy;
            island.applyFilter(island, island.rect, FP.zero, ISLAND_STYLE_FILTER);
            island.applyFilter(island, island.rect, FP.zero, ISLAND_OUTLINE_FILTER);
            island = MapUtils.pixelate(island);
            _image = new Image(island);
            _rect = r;
            graphic = _image;
            mask = new Pixelmask(island);
            x = (r.x-4), y = (r.y-4);
            _area = r.width * r.height;
            type = "island";
        }
        
        override public function added():void {
            layer = 1;
        }
        
        public function get area():int { return _area; }
        
        public function get perimeter():Vector.<Point> {
            if (!_perimeter) {
                _perimeter = MapUtils.perimeter(_image.source);
            }
            return _perimeter;
        }
        
        private function createBitmapData(rect:Rectangle, mask_pixels:Vector.<uint>, noise_pixels:Vector.<uint>):BitmapData {
            var r:Rectangle = new Rectangle(0, 0, rect.width, rect.height);
            var mask_data:BitmapData = new BitmapData(rect.width, rect.height, true, 0x00000000);
            var noise_data:BitmapData = mask_data.clone();
            var island:BitmapData = mask_data.clone();
            var job:ShaderJob = new ShaderJob(_shader, island);
            
            mask_data.setVector(r, mask_pixels);
            noise_data.setVector(r, noise_pixels);
            
            _shader.data.noise.input = noise_data;
            _shader.data.mask.input = mask_data;
            job.start(true);
            
            return island;
        }
    }
}