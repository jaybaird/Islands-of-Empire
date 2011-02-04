// Code from http://wonderfl.net/code/13dbc50eb48b0bfd6920540c228e8ba9ae75b601
// license : MIT License
// http://www.opensource.org/licenses/mit-license.php
package gfx {
    import flash.display.*;
    import flash.events.*;
    import flash.geom.*;
    import flash.media.*;
    import flash.utils.*;
    import flash.filters.*;
    import gfx.Particle;

    public class Fireworks extends Sprite {
        private var rect:Rectangle;
        private var fwBitmapData:BitmapData;
        private var glowBitmapData:BitmapData;
        private var fwBitmap:Bitmap;
        private var glowBitmap:Bitmap;
        private var glowMatrix:Matrix;
        private var glowScale:Number;
        private var fw_width:Number;
        private var fw_height:Number;
        private var explosionX:int;
        private var explosionY:int;
        private var maxParticles:Number;
        private var particlesArray:Array;
        private static  var CPAL:Array = ["0xFFFFFF","0xFF0000","0xFF6600",
         "0xF8FF00","0x00FF08","0x0009FF","0xC5B358"];
        
        private var customColor:Boolean;
        
        private var launchSpeed:Number;
        
        private var bFilter:BlurFilter;
        private var cTransform:ColorTransform;
        private var point:Point;
        
        private var radius:Number;
        private var angle:Number;
        
        private var es:int;
        
        private var part:Particle;
        private var partShow:Particle;
        
        private var pColor:uint;
        
        private var timer:Timer;

        public function Fireworks(fww:Number,fwh:Number) {
        
        /********************************************************
         * Settings :                                           *
         *      You can edit some settings below to your needs. *
         *      Check the comments above the values             *
         ********************************************************/

            /* 250 particles are enough for good fireworks. Increasing the number 
             * may result in high cpu usage with bad effect.
             */
            maxParticles = 250;
            
            /* Size of the glow effect in the blinking particles.
             * Bigger the value bigger the glow.
             */
            glowScale = 2;
            
            /* Set this variable to false if you dont want to use custom colors.
             * Random colors will be displayed in the fireworks.
             */                          
            customColor = false;
            
            /* Blur amount used if the blur filter effect is used.
             * Remove the comment in renderfw() function 3'rd line to use it.
             */                     
            
            
            /* Increasing the alphaMultiplier value will show some trail effect.
             * Keep it below .90
             */             
            cTransform = new ColorTransform();
            cTransform.alphaMultiplier = .65;
            
            /* Set the explosion size of the firework.
             * Bigger the value bigger the explosion size.
             */             
            es = 10;

            fw_width = fww;
            fw_height = fwh;
            rect = new Rectangle(0,0,fw_width,fw_height);
            
            fwBitmapData = new BitmapData(rect.width,rect.height,false,0x000000);
            fwBitmap = new Bitmap(fwBitmapData);
            fwBitmap.blendMode = BlendMode.SCREEN;
            this.addChild(fwBitmap);

            glowBitmapData = new BitmapData(rect.width/glowScale,rect.height/glowScale,false,0x0000000);
            glowBitmap = new Bitmap(glowBitmapData,PixelSnapping.NEVER, true);
            glowBitmap.scaleX = glowBitmap.scaleY = glowScale;
            glowBitmap.blendMode = BlendMode.ADD;
            this.addChild(glowBitmap);

            glowMatrix = new Matrix(1/glowScale, 0, 0, 1/glowScale);
            particlesArray = [];
            point = new Point();
            radius = 0;
            angle = 0;

            this.addEventListener(Event.ENTER_FRAME,enterFrameHandler);
            
            /* Every 2 seconds the launch function is called.
             * Lower value will produce more fireworks but will affect the cpu.
             */                 
            timer = new Timer(2000);
            timer.addEventListener(TimerEvent.TIMER, launch);
            timer.start();
            launch(null);
        }
        
        private function launch(tevent:TimerEvent):void {
            
            var ran:int = Math.floor(1 + (Math.random() * 4));
            for (var i:int = 0; i < ran; i++) {
                launchRocket();
            }
        }

        private function enterFrameHandler(event:Event):void {
            renderfw();
        }
        private function renderfw():void {
            fwBitmapData.lock();
            
            
            fwBitmapData.colorTransform(fwBitmapData.rect, cTransform);
            for (var k:int = 0; k < particlesArray.length; k++) {
                partShow = particlesArray[k];
                switch (partShow.explode) {
                    case 1 : 
                        partShow.vy += 0.09;
                        partShow.vx *= 0.9;
                        partShow.vy *= 0.9;
                        partShow.px += partShow.vx;
                        partShow.py += partShow.vy;

                        fwBitmapData.setPixel(int(partShow.px),int(partShow.py),partShow.pColor)
                        break;
                    case 2 : 
                        partShow.sy -= partShow.lSpeed;
                        
                        if (partShow.sy <= partShow.py) {
                            
                            partShow.explode = 1;
                        }
                        if (int(Math.random() * 20) == 0) {
                            var i:int = int(Math.random() * 1);
                            var j:int = int(Math.random() * 8);
                            fwBitmapData.setPixel(partShow.sx + i,partShow.sy + j,0xFFFFFF)
                        }
                        break;
                }
                if ((partShow.px > fw_width || partShow.px < 0) || (partShow.py < 0 || partShow.py > fw_height) || Math.abs(partShow.vx) < .01 || Math.abs(partShow.vy) < .01) {
                    this.particlesArray.splice(k, 1);
                }
            }
            fwBitmapData.unlock();
        }
        
        private function setColorPixels(i:int,j:int,k:uint):void {
            fwBitmapData.setPixel(i,j,k);
        }
        
        private function setGlowPixels():void {
            glowBitmapData.draw(fwBitmapData, glowMatrix);
        }
        
        private function launchRocket():void {
            
            explosionX = int((Math.random() * (rect.width-100)) + 50);
            
            
            explosionY = int((Math.random() * (rect.height-200)) + 50);
            
            launchSpeed = int((Math.random() * 8) + 5);
            
            if (customColor == true) {
                pColor = CPAL[int(Math.random () * (CPAL.length))];
            } else {
                pColor = Math.random() * 0xFFFFFF;
            }

            if (rect.contains(explosionX,explosionY)) {
                
                for (var p:int = 0; p < maxParticles; p++) {
                    part = new Particle();

                    
                    part.px = explosionX;
                    part.py = explosionY;

                    
                    radius = Math.sqrt(Math.random()) * es;
                    angle = Math.random()*(Math.PI) * 2;
                    part.vx = Math.cos(angle) * radius;
                    part.vy = Math.sin(angle) * radius;


                    
                    
                    

                    
                    
                    
                    if (int(4 * Math.random()) == 0) {
                        part.pColor = 0xFFFFFF;
                    } else {
                        part.pColor = pColor;
                    }
                    
                    
                    part.sx = explosionX;
                    part.sy = rect.height - 5;

                    
                    
                    part.explode = 2;
                    part.lSpeed = launchSpeed;
                    particlesArray.push(part);
                }
            }
        }
    }
}