package world.entities {
    import flash.display.Bitmap;
    
    import net.flashpunk.Entity;
    import net.flashpunk.graphics.Stamp;
    
    public class Zone extends Entity {
        [Embed(source='/assets/sprites/landing_zone.png')] public static const ZONE:Class;
        
        public function Zone(end_x:int, end_y:int):void {
            var bmp:Bitmap = new ZONE();
            x = end_x - bmp.width, y = end_y - bmp.height/2;
            setHitbox(bmp.width, bmp.height, 0, 0);
            graphic = new Stamp(bmp.bitmapData);
        }
    }
}