package gfx {
    import flash.utils.*;
    import flash.geom.*;
    import flash.events.*;
    import flash.display.*;
    import flash.filters.BitmapFilterQuality;
    import flash.filters.GlowFilter;

    import net.flashpunk.*;
    import net.flashpunk.tweens.misc.Alarm;

    import world.*;
    import world.entities.*;

    import com.gskinner.motion.*;
    import com.gskinner.motion.plugins.*;
    import com.gskinner.motion.easing.*;

    public class Fog extends Bitmap {
        private static var _instance:Fog;
        private static var _timer:Alarm;
        
        public function Fog(p_key:SingletonBlocker):void {
            bitmapData = new BitmapData(FP.screen.width, FP.screen.height, true, 0x44000000);
            blendMode = BlendMode.LAYER;
            //_timer = new Alarm(.03, update, Tween.LOOPING);
            //_timer = new Timer(30);
            //_timer.addEventListener(TimerEvent.TIMER, update);
            visible = false;
            addEventListener(Event.ENTER_FRAME, update);
        }
        
        //override public function set visible(value:Boolean):void {
        //    super.visible = value;
        //    if (value) {
        //        if (FP.world.hasTween(_timer)) {
        //            _timer.reset(.03);
        //            _timer.active = true;
        //        } else {
        //            FP.world.addTween(_timer, true);
        //        }
        //    } else {
        //        _timer.active = false;
        //    }
        //}
        
        public function fadeIn():void {
            alpha = 0;
            visible = true;
            new GTween(this, .5, {'alpha':1}, {'ease':Linear.easeNone});
        }
        
        public function fadeOut():void {
            new GTween(this, .5, {'alpha':1}, {'ease':Linear.easeNone, 'onComplete':function():void {
                visible = true;
            }});
        }
        
        public static function instance():Fog {
            if (_instance == null) {
                _instance = new Fog(new SingletonBlocker());
            }
            return _instance;
        }
        
        public function update(evt:Event):void {
            bitmapData.lock();
            bitmapData.fillRect(bitmapData.rect, 0x44000000);
            var _mask_matrix:Matrix = new Matrix(1, 0, 0, 1);
            for each(var s:Ship in Main.ships) {
                if (!s || s.position == null || !s.visible) continue;
                _mask_matrix.tx = s.position.x-s.sightDistance-50;
                _mask_matrix.ty = s.position.y-s.sightDistance-50-(Ship.WIDTH/2);
                bitmapData.draw(s.fogMask, _mask_matrix, null, BlendMode.ERASE);
            }
            bitmapData.unlock();
        }
    }
}

internal class SingletonBlocker {}