package world {
    import flash.utils.*;
    import flash.geom.*;
    import flash.display.*;
    
    import net.flashpunk.*;
    import net.flashpunk.graphics.*;
    import net.flashpunk.tweens.misc.Alarm;
    
    import gfx.*;
    import util.MapUtils;
    import world.entities.*;
    import world.entities.layers.Background;
    
    public class BaseMap extends World {
        [Embed(source="/assets/filters/AreaMask.pbj", mimeType="application/octet-stream")]
        public static const AREA_MASK:Class;
        
        public static const SMALL:uint = 130;
        public static const FLOOD_FILL_COLOR:uint = 0xffff0000;
        public static const PROCESSED_FILL_COLOR:uint = 0xff00ff00;
        
        protected var _base:BitmapData;
        protected var _map_data:BitmapData;
        protected var _closed:Object;
        protected var _islands:Vector.<Island>;
        protected var _island_data:Vector.<Object>;
        protected var _background:Background;
        protected var _in_transition:Boolean;
        
        protected static var _shader:Shader;
        {
            _shader = new Shader(new AREA_MASK() as ByteArray);
            _shader.precisionHint = ShaderPrecision.FAST;
        }
        
        public function BaseMap(seed:int, closed:Boolean=false):void {
            super();
            FP.randomSeed = seed;
            _islands = new Vector.<Island>();
            if (closed) {
                _closed = {
                    top: false,
                    left: false,
                    right: false,
                    bottom: false
                };
            } else {
                _closed = {
                    top: FP.random > 0.5,
                    left: FP.random > 0.5
                };
                _closed.bottom = (_closed.top) ? false : true;
                _closed.right = (_closed.left) ? false : true;
            }
            _base = new BitmapData(FP.screen.width, FP.screen.height, true, 0xffffff);
            _base.perlinNoise(SMALL, SMALL, 6, seed, false, true, BitmapDataChannel.ALPHA, false, null);
            _island_data = new Vector.<Object>();
            MapUtils.mapData = createIslands(_base);
        }
        
        public function set islands(value:Vector.<Island>):void { _islands = value; }
        public function get islands():Vector.<Island> { return _islands; }
        
        public function init():void {
            buildIslands();
            cueBirds();
        }
        
        private function checkBlob(blob_rect:Rectangle):Boolean {
            if (blob_rect.width < 10 && blob_rect.height < 10) return false;
            if (_closed.right && blob_rect.right == FP.screen.width) return false;
            if (_closed.top && blob_rect.top == 0) return false;
            if (_closed.left && blob_rect.left == 0) return false;
            if (_closed.bottom && blob_rect.bottom == FP.screen.height) return false;

            return true;
        }
        
        private function cueBirds():void {
            var spread:int = 35;
            var min_y:int = spread, max_y:int = FP.screen.height-spread;
            var num_birds:int = Main.random(20, 5);
            var y_pos:int = Main.random(max_y, min_y);
            min_y = FP.clamp(y_pos-spread, min_y, max_y);
            max_y = FP.clamp(y_pos+spread, min_y, max_y);
            for (var i:int = 0; i < num_birds; i++) {
                addTween(new Alarm(Main.randomFloat(.750, .250), function():void {
                    var bird:Bird = FP.world.create(Bird, true);
                    bird.x = -20, bird.y = Main.random(max_y, min_y);
                }, Tween.ONESHOT), true)
            }
            addTween(new Alarm(Main.random(20, 7), cueBirds, Tween.ONESHOT), true);
        }
        
        public function buildIslands():void {
            var island:Island;
            _background = new Background(_base);
            add(_background);
            for (var i:int=0; i < _island_data.length; i++) {
                island = new Island(_island_data[i].rect,
                                    _island_data[i].data,
                                    _base.getVector(_island_data[i].rect));
                _islands.push(island);
                add(island);
            }
            _islands.sort(function(a:Island, b:Island):int {
                return (a.area < b.area) ? 1 : (a.area == b.area) ? 0 : -1;
            });
        }
        
        private function createIslands(data:BitmapData):BitmapData {
            trace("[MAP] building map...");
            var start:int = getTimer();
            var area_data:BitmapData = new BitmapData(data.width, data.height, true, 0);
            var job:ShaderJob = new ShaderJob(_shader, area_data);
            _shader.data.src.input = data;
            job.start(true);
            for(var x:int = 0; x < data.width; x+=5) {
                for(var y:uint = 0; y < data.height; y+=5) {
                    if(area_data.getPixel(x, y) != 0xffffff) continue;
                    area_data.floodFill(x, y, FLOOD_FILL_COLOR);
                    var blob_rect:Rectangle = area_data.getColorBoundsRect(0xffffffff, FLOOD_FILL_COLOR);
                    if (checkBlob(blob_rect)) {
                        var blob_data:Vector.<uint> = area_data.getVector(blob_rect);
                        _island_data.push({"rect":blob_rect, "data":blob_data});
                        area_data.floodFill(x, y, PROCESSED_FILL_COLOR);
                    } else {
                        area_data.floodFill(x, y, 0xff000000);
                    }
                }
            }
            area_data = MapUtils.pixelate(area_data);
            //Hud.instance.addChild(new Bitmap(area_data));
            trace("[MAP] Building map took: ", getTimer() - start);
            return area_data;
        }
    }
}