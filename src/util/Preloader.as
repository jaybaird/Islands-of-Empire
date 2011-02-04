package util {
    import mochi.as3.*;
    import flash.geom.*;
    import flash.text.*;
    import flash.display.*;
    
    import com.bit101.components.*;
    
    public class Preloader extends AbstractPreloader {
        [Embed(source='/assets/splash/loading.png')] private const LOADING:Class;
        
        public static var rootClip:MovieClip;
        
        private var _bmp:Bitmap;
        private var _loading:Bitmap;
        private var _bmpd:BitmapData;

        public function Preloader() {
            super();
            rootClip = this;
        }

        override protected function beginLoading():void {
            _bmpd = new BitmapData(300, 7, false, 0);
            _bmp = new Bitmap(_bmpd);
            _bmp.x = 380, _bmp.y = 310;
            _loading = new LOADING();
            addChild(_loading);
            addChild(_bmp);
        }

        override protected function updateLoading(a_percent:Number):void {
            _bmpd.fillRect(new Rectangle(2, 2, Math.round(a_percent * (_bmpd.width-3)), 3), 0xffffff);
        }

        override protected function endLoading():void {
            removeChild(_loading);
            removeChild(_bmp);
            _bmp = null;
            _loading = null;
            _bmpd.dispose();
        }
    }
}