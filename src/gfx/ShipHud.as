package gfx {
    import flash.display.*;
    import flash.geom.*;
    
    import org.osflash.signals.Signal;
    import net.flashpunk.FP;
    import net.flashpunk.utils.Draw;
    
    import world.entities.*;
    
    public class ShipHud extends Sprite {
        private const TOTAL_ANGLE:Number = 120;
        private const RADIUS:Number =  20;
        private const TO_RADIANS:Number =  Math.PI/180;
        private var _ship:Damageable;
        private var _renderShape:Shape;
        private var _source:BitmapData;
        private var _needs_update:Boolean;
        private var _percentage:Number;
        
        private var _override_color:uint;
        
        public var didUpdate:Signal;
        
        public function ShipHud(ship:Damageable, color:uint=0):void {
            _ship = ship;
            _renderShape = new Shape();
            _source = new BitmapData(72, 72, true, 0);
            update(100);
            didUpdate = new Signal();
            addChild(_renderShape);
            cacheAsBitmap = true;
            if (color != 0) {
                _override_color = color;
            }
        }

        public function update(percentage:Number):void {
            _percentage = percentage / FP.getClass(_ship).TOTAL_HEALTH;
            _needs_update = true;
        }
        
        private function doUpdate():void {
            _renderShape.graphics.clear();
            // render the background
            renderLine(1*TOTAL_ANGLE, 0x333333);
            if (_percentage <= .30) {
                renderLine(_percentage*TOTAL_ANGLE, (_override_color == 0) ? 0xFF0000 : _override_color);
            } else {
                renderLine(_percentage*TOTAL_ANGLE, (_override_color == 0) ? 0x00FF00 : _override_color);
            }
            // draw the under circle
            //graphics.lineStyle(1, 0xCCCCCC);
            //graphics.drawEllipse(_ship.x + 12 , _ship.y + 40, FP.getClass(_ship).WIDTH, 8);
            _source.fillRect(_source.rect, 0);
            _source.draw(this);
            _needs_update = false;
        }
        
        public function render():void {
            if (!_source || !visible) return;
            if (_needs_update) doUpdate();
            if (FP.getClass(_ship) == Fort) {
                FP.point.x = (_ship.x - 25);
                FP.point.y = (_ship.y - 42);
            } else if (FP.getClass(_ship) == Airship) {
                FP.point.x = (_ship.x - FP.getClass(_ship).WIDTH/2) + _ship.graphic.x;
                FP.point.y = (_ship.y - FP.getClass(_ship).WIDTH + 8) + _ship.graphic.y;
            } else {
                FP.point.x = (_ship.x - FP.getClass(_ship).WIDTH/2) + _ship.graphic.x;
                FP.point.y = (_ship.y - FP.getClass(_ship).WIDTH + 4) + _ship.graphic.y;
            }
            FP.buffer.copyPixels(_source, _source.rect, FP.point, null, null, true);
        }
        
        private function renderLine(angle:Number, color:uint):void {
            // calculate 30-degree segments for accuracy
            var endx:Number;
            var endy:Number;
            var ax:Number;
            var ay:Number;
            var nSeg:Number = Math.floor(angle/30);// eg 2 if angle is 80
            var pSeg:Number = angle-(nSeg*30);// eg 20 if angle is 80
            var command_vec:Vector.<int> = new Vector.<int>();
            var path_vec:Vector.<Number> = new Vector.<Number>();
            var a:Number = 0.268;// tan(15)
            
            command_vec.push(GraphicsPathCommand.MOVE_TO);
            path_vec.push(RADIUS, 0);
            // draw the 30-degree segments
            for (var i:int = 0; i<nSeg; i++) {
                endx = RADIUS*Math.cos((i+1)*30*TO_RADIANS);
                endy = RADIUS*Math.sin((i+1)*30*TO_RADIANS);
                ax = endx+RADIUS*a*Math.cos(((i+1)*30-90)*TO_RADIANS);
                ay = endy+RADIUS*a*Math.sin(((i+1)*30-90)*TO_RADIANS);
                command_vec.push(GraphicsPathCommand.CURVE_TO);
                path_vec.push(ax, ay, endx, endy);
            }
            // draw the remainder
            if (pSeg>0) {
                a = Math.tan(pSeg/2*TO_RADIANS);
                endx = RADIUS*Math.cos((i*30+pSeg)*TO_RADIANS);
                endy = RADIUS*Math.sin((i*30+pSeg)*TO_RADIANS);
                ax = endx+RADIUS*a*Math.cos((i*30+pSeg-90)*TO_RADIANS);
                ay = endy+RADIUS*a*Math.sin((i*30+pSeg-90)*TO_RADIANS);
                command_vec.push(GraphicsPathCommand.CURVE_TO);
                path_vec.push(ax, ay, endx, endy);
            }
            with(_renderShape) {
                rotation = 0;
                graphics.lineStyle(3, color);
                graphics.drawPath(command_vec, path_vec);
                // rotate the wedge to its correct location in the renderShape
                x = 24;
                y = 36;
                rotation = 125;
            }
        }
    }
}