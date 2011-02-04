package components {
    import flash.display.DisplayObjectContainer;
    
    import com.bit101.components.*;
    
    import world.entities.Ship;
    
    public class QueryWindow extends RoundedPanel {
        private var _ship_name:Text;
        private var _hit_rate:Text;
        private var _hits:Text;
        private var _kills:Text;
        private var _shots_fired:Text;
        
        public function QueryWindow(p:DisplayObjectContainer, x:int, y:int):void {
            super(p, x, y);
            width = 250, height = 40;
            alpha = .85;
            _ship_name = new Text(this, 5, 5, "");
        }
        
        public function updateData(s:Ship):void {
            _ship_name.text = s.name;
        }
    }
}