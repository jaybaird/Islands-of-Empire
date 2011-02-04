/**
 * WheelMenu.as
 * Keith Peters
 * version 0.97
 * 
 * A radial menu that pops up around the mouse.
 * 
 * Copyright (c) 2009 Keith Peters
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 * 
 * 
 * 
 * Components with text make use of the font PF Ronda Seven by Yuusuke Kamiyamane
 * This is a free font obtained from http://www.dafont.com/pf-ronda-seven.font
 */
 
package components
{
    import flash.utils.Dictionary;
    import flash.geom.Point;
	import flash.display.*;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.text.*;
	import flash.events.MouseEvent;
	import flash.filters.DropShadowFilter;

    import com.bit101.components.*;
    
    import org.osflash.signals.Signal;
    
    import com.gskinner.motion.*;
    import com.gskinner.motion.plugins.*;
    import com.gskinner.motion.easing.*;
    
    import net.flashpunk.FP;
    
    import gfx.ToolTip;

	public class CommandWheel extends Component
	{
	    public static const SELECTED:String = "selected";
	    
		private var _borderColor:uint = 0x999999;
		private var _buttons:Array;
		private var _color:uint = 0x000000;
		private var _highlightColor:uint = 0xeeeeee;
		private var _iconRadius:Number;
		private var _innerRadius:Number;
		private var _items:Array;
		private var _numButtons:int;
		private var _outerRadius:Number;
		private var _selectedIndex:int = -1;
		private var _startingAngle:Number = -90;
		private var _info_window:Panel;
		
		private var _item_selected:Signal;
		private var _hidden:Signal;
		private var _callback:Function;
		
		private var _orig_x:int;
		private var _orig_y:int;
		
		private var _tooltips:Dictionary;
		private var _is_open:Boolean;
		
		/**
		 * Constructor
		 * @param parent The parent DisplayObjectContainer on which to add this component.
		 * @param numButtons The number of segments in the menu
		 * @param outerRadius The radius of the menu as a whole.
		 * @parem innerRadius The radius of the inner circle at the center of the menu.
		 * @param defaultHandler The event handling function to handle the default event for this component (select in this case).
		 */
		public function CommandWheel(parent:DisplayObjectContainer, numButtons:int, outerRadius:Number = 80, iconRadius:Number = 60, innerRadius:Number = 10):void
		{
			_numButtons = numButtons;
			_outerRadius = outerRadius;
			_iconRadius = iconRadius;
			_innerRadius = innerRadius;
			_item_selected = new Signal(Point, String);
			_hidden = new Signal();
			_tooltips = new Dictionary(true);
			super(parent);
		}
		
		public function get itemSelected():Signal { return _item_selected; }
		public function get hidden():Signal { return _hidden; }	
		
		///////////////////////////////////
		// protected methods
		///////////////////////////////////
		
		/**
		 * Initializes the component.
		 */
		override protected function init():void
		{
			super.init();
			_items = new Array();
			makeButtons();

			hide();
		}
		
		/**
		 * Creates the buttons that make up the wheel menu.
		 */
		protected function makeButtons():void
		{
			_buttons = new Array();
			for(var i:int = 0; i < _numButtons; i++)
			{
				var btn:ArcButton = new ArcButton(Math.PI * 2 / _numButtons, _outerRadius, _iconRadius, _innerRadius);
				btn.id = i;
				btn.rotation = _startingAngle + 360 / _numButtons * i;
				btn.addEventListener(Event.SELECT, onSelect);
				addChild(btn);
				_buttons.push(btn);
			}
		}
		
		///////////////////////////////////
		// public methods
		///////////////////////////////////
		
		/**
		 * Hides the menu.
		 */
		public function hide():void
		{
			visible = false;
			if (stage) {
			    stage.removeEventListener(MouseEvent.MOUSE_UP, onStageMouseUp);
			}
			_hidden.dispatch();
		}
		
		/**
		 * Sets the icon / text and data for a specific menu item.
		 * @param index The index of the item to set icon/text and data for.
		 * @iconOrLabel Either a display object instance, a class that extends DisplayObject, or text to show in a label.
		 * @data Any data to associate with the item.
		 */
		public function setItem(index:int, iconOrLabel:Object, data:Object = null, disabled:Boolean=false, tooltext:String=""):void
		{
			_buttons[index].setIcon(iconOrLabel);
			_buttons[index].disabled = disabled;
			createToolTip((_buttons[index] as ArcButton), (iconOrLabel as String), tooltext);
			_items[index] = data;
		}
		
		private function createToolTip(obj:ArcButton, title:String="", txt:String="", align:String="center"):void {
            var tt:ToolTip = new ToolTip();
            tt.delay = 800; 
            tt.titleEmbed = tt.contentEmbed = true;
            tt.titleFormat = tt.contentFormat = new TextFormat(Style.fontName, Style.fontSize, Style.LABEL_TEXT);
            tt.hook = false, tt.align = align;
            tt.colors = 0x000000, tt.bgAlpha = 1;
            if (txt == "") {
                tt.cornerRadius = 5, 
                tt.autoSize = true;
            } else {
                tt.cornerRadius = 10, 
                tt.tipWidth = int(obj.width * 2);
            }
            
            obj.addEventListener(MouseEvent.ROLL_OVER, function(evt:MouseEvent):void {
                tt.minY = y + obj.iconHolder.y;
                tt.show(obj, title, txt);
            })
            _tooltips[obj] = tt;
        }
		
		/**
		 * Shows the menu - placing it on top level of parent and centering around mouse.
		 */
		public function show():void
		{
		    if (parent.contains(this) && visible) return;
			parent.addChild(this);
			_orig_x = x = int(parent.mouseX);
			_orig_y = y = int(parent.mouseY);
			if (y - _outerRadius < 0) y = _outerRadius + 20;
			if (x - _outerRadius < 0) x = _outerRadius + 20;
			if (x + _outerRadius > FP.screen.width) x = FP.screen.width - _outerRadius - 20;
			if (y + _outerRadius > FP.screen.height) y = FP.screen.height - _outerRadius - 20;
			_selectedIndex = -1;
			scaleX = scaleY = 0;
			visible = true;
			new GTween(this, .1, {'scaleX':1, 'scaleY': 1}, {'ease':Linear.easeNone});
			stage.addEventListener(MouseEvent.MOUSE_UP, onStageMouseUp);
			_is_open = true;
		}
		
		///////////////////////////////////
		// event handlers
		///////////////////////////////////
		
		/**
		 * Called when one of the buttons is selected. Sets selected index and dispatches select event.
		 */
		protected function onSelect(event:Event):void
		{
			_selectedIndex = event.target.id;
			_item_selected.dispatch(new Point(_orig_x, _orig_y), selectedItem);
		}
		
		/**
		 * Called when mouse is released. Hides menu.
		 */
		protected function onStageMouseUp(event:MouseEvent):void
		{
		    new GTween(this, .1, {'scaleX':0, 'scaleY': 0}, {'ease':Linear.easeNone, 'onComplete':function():void {
		        hide();
		    }});
		}
		
		///////////////////////////////////
		// getter / setters
		///////////////////////////////////
		
		/**
		 * Gets / sets the color of the border around buttons.
		 */
		public function set borderColor(value:uint):void
		{
			_borderColor = value;
			for(var i:int = 0; i < _numButtons; i++)
			{
				_buttons[i].borderColor = _borderColor;
			}
		}
		public function get borderColor():uint
		{
			return _borderColor;
		}
		
		/**
		 * Gets / sets the base color of buttons.
		 */
		public function set color(value:uint):void
		{
			_color = value;
			for(var i:int = 0; i < _numButtons; i++)
			{
				_buttons[i].color = _color;
			}
		}
		public function get color():uint
		{
			return _color;
		}
		
		/**
		 * Gets / sets the highlighted color of buttons.
		 */
		public function set highlightColor(value:uint):void
		{
			_highlightColor = value;
			for(var i:int = 0; i < _numButtons; i++)
			{
				_buttons[i].selectedColor = _highlightColor;
			}
		}
		public function get highlightColor():uint
		{
			return _highlightColor;
		}
		
		/**
		 * Gets the selected index.
		 */
		public function get selectedIndex():int
		{
			return _selectedIndex;
		}
		
		/**
		 * Gets the selected item.
		 */
		public function get selectedItem():Object
		{
			return _items[_selectedIndex];
		}
		
	
		public function get buttons():Array
		{
		    return _buttons;
		}
	}
}


/**
 * ArcButton class. Internal class only used by WheelMenu.
 */
import flash.display.DisplayObject;
import flash.display.Sprite;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.utils.getDefinitionByName;
import flash.display.Shape;
import com.bit101.components.Label;
import components.CommandWheel;

class ArcButton extends Sprite
{
	public var id:int;
	
	private var _arc:Number;
	private var _bg:Shape;
	private var _borderColor:uint = 0;
	private var _color:uint = 0x000000;
	private var _highlightColor:uint = 0xcccccc;
	private var _icon:DisplayObject;
	private var _iconHolder:Sprite;
	private var _iconRadius:Number;
	private var _innerRadius:Number;
	private var _outerRadius:Number;
	private var _disabled:Boolean;
	private var _tooltext:String;
	/**
	 * Constructor.
	 * @param arc The radians of the arc to draw.
	 * @param outerRadius The outer radius of the arc. 
	 * @param innerRadius The inner radius of the arc.
	 */
	public function ArcButton(arc:Number, outerRadius:Number, iconRadius:Number, innerRadius:Number)
	{
		_arc = arc;
		_outerRadius = outerRadius;
		_iconRadius = iconRadius;
		_innerRadius = innerRadius;
		
		_bg = new Shape();
		addChild(_bg);
		
		_iconHolder = new Sprite();
		addChild(_iconHolder);
		
		drawArc(_color);
		addEventListener(MouseEvent.MOUSE_OVER, onMouseOver);
		addEventListener(MouseEvent.MOUSE_OUT, onMouseOut);
		addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
	}
	
	///////////////////////////////////
	// private methods
	///////////////////////////////////
	
	/**
	 * Draws an arc of the specified color.
	 * @param color The color to draw the arc.
	 */
	protected function drawArc(color:uint):void
	{
	    var alpha:Number = .4;
		_bg.graphics.clear();
		if (_disabled)
		    alpha = .3;
		//_bg.graphics.lineStyle(2, _borderColor, alpha);
		_bg.graphics.beginFill(color, alpha);
		_bg.graphics.moveTo(_innerRadius, 0);
		_bg.graphics.lineTo(_outerRadius, 0);
		for(var i:Number = 0; i < _arc; i += .05)
		{
			_bg.graphics.lineTo(Math.cos(i) * _outerRadius, Math.sin(i) * _outerRadius);
		}
		_bg.graphics.lineTo(Math.cos(_arc) * _outerRadius, Math.sin(_arc) * _outerRadius);
		_bg.graphics.lineTo(Math.cos(_arc) * _innerRadius, Math.sin(_arc) * _innerRadius);
		for(i = _arc; i > 0; i -= .05)
		{
			_bg.graphics.lineTo(Math.cos(i) * _innerRadius, Math.sin(i) * _innerRadius);
		}
		_bg.graphics.lineTo(_innerRadius, 0);
		
		graphics.endFill();
	}
	
	///////////////////////////////////
	// public methods
	///////////////////////////////////
	
	public function set disabled(value:Boolean):void {
	    _disabled = value;
	    drawArc(_color);
	}
	
	/**
	 * Sets the icon or label of this button.
	 * @param iconOrLabel Either a display object instance, a class that extends DisplayObject, or text to show in a label.
	 */
	public function setIcon(iconOrLabel:Object):void
	{
		if(iconOrLabel == null) return;
		while(_iconHolder.numChildren > 0) _iconHolder.removeChildAt(0);
		if(iconOrLabel is Class)
		{
			_icon = new iconOrLabel() as DisplayObject;
		}
		else if(iconOrLabel is DisplayObject)
		{
			_icon = iconOrLabel as DisplayObject;
		}
		else if(iconOrLabel is String)
		{
			_icon = new Label(null, 0, 0, iconOrLabel as String);
			(_icon as Label).draw();
		}
		if(_icon != null)
		{
			var angle:Number = _bg.rotation * Math.PI / 180;
			_icon.x = Math.round(-_icon.width / 2);
			_icon.y = Math.round(-_icon.height / 2);
			_iconHolder.addChild(_icon);
			_iconHolder.x = Math.round(Math.cos(angle + _arc / 2) * _iconRadius);
			_iconHolder.y = Math.round(Math.sin(angle + _arc / 2) * _iconRadius);
		    //_iconHolder.graphics.beginFill(0x000000);
		    //_iconHolder.graphics.drawRoundRect(_icon.x - 2, _icon.y-2, _iconHolder.width + 4, _iconHolder.height + 4, 5, 5);
		}
	}
	
	public function get iconHolder():Sprite { return _iconHolder; }
	
	///////////////////////////////////
	// event handlers
	///////////////////////////////////
	
	/**
	 * Called when mouse moves over this button. Draws highlight.
	 */
	protected function onMouseOver(event:MouseEvent):void
	{
	    if (!_disabled) {
		    drawArc(_highlightColor);
		}
		
	}
	
	/**
	 * Called when mouse moves out of this button. Draw base color.
	 */
	protected function onMouseOut(event:MouseEvent):void
	{
	    if (!_disabled)
		    drawArc(_color);
	}
	
	/**
	 * Called when mouse is released over this button. Dispatches select event.
	 */
	protected function onMouseUp(event:MouseEvent):void
	{
	    if (!_disabled)
		    dispatchEvent(new Event(Event.SELECT));
	}

	
	///////////////////////////////////
	// getter / setters
	///////////////////////////////////
	
	public function set arc(value:int):void {
	    _arc = value;
	    drawArc(_color);
	}
	
	/**
	 * Sets / gets border color.
	 */
	public function set borderColor(value:uint):void
	{
		_borderColor = value;
		drawArc(_color);
	}
	public function get borderColor():uint
	{
		return _borderColor;
	}
	
	/**
	 * Sets / gets base color.
	 */
	public function set color(value:uint):void
	{
		_color = value;
		drawArc(_color);
	}
	public function get color():uint
	{
		return _color;
	}
	
	/**
	 * Sets / gets highlight color.
	 */
	public function set highlightColor(value:uint):void
	{
		_highlightColor = value;
	}
	public function get highlightColor():uint
	{
		return _highlightColor;
	}
	
	/**
	 * Overrides rotation by rotating arc only, allowing label / icon to be unrotated.
	 */
	override public function set rotation(value:Number):void
	{
		_bg.rotation = value;
	}
	override public function get rotation():Number
	{
		return _bg.rotation;
	}
	
	public function set tooltext(value:String):void { _tooltext = value; }
	
	public function get disabled():Boolean { return _disabled; }
}
