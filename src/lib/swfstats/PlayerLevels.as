package lib.swfstats
{
    import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.events.IOErrorEvent;
	import flash.events.HTTPStatusEvent;
	import flash.events.SecurityErrorEvent;
	import flash.events.Event;
	import flash.geom.Matrix;
	import flash.net.URLRequest;
	import flash.net.URLLoader;
	import flash.net.URLVariables;
	import flash.net.URLRequestMethod;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequestHeader;
	import flash.net.SharedObject;	
	import flash.utils.Dictionary;

	public final class PlayerLevels
	{
		private static var ListCallback:Function = null;
		private static var LoadCallback:Function = null;
		private static var SaveCallback:Function = null;		
		private static var RateCallback:Function = null;
		private static var SaveLevel:PlayerLevel;
		private static var RateLevel:String;
		private static var RateAmount:int;
		
		// status messages
		public static const SAVE_COMPLETE:int = 0;
		public static const SAVE_FAILED_LEVEL_EXISTS:int = 1;
		public static const SAVE_FAILED_GENERAL_ERROR:int = 2;
		public static const SAVE_FAILED_INVALID_HASH:int = 4;
		public static const SAVE_INVALID_THUMB:int = 3;		

		public function PlayerLevels() { } 
		
		// rating
		public static function Rate(levelid:String, rating:int, callback:Function):Boolean
		{
			if(RateCallback != null)
				return false;
			
			var cookie:SharedObject = SharedObject.getLocal("ratings");
			
			if(cookie.data[levelid] != null)
				return false;

			RateCallback = callback;
			RateLevel = levelid;
			RateAmount = rating;

			var loader:URLLoader = new URLLoader();
			loader.addEventListener(Event.COMPLETE, RateComplete);
			loader.addEventListener(IOErrorEvent.IO_ERROR, RateErrorHandler);
			loader.addEventListener(HTTPStatusEvent.HTTP_STATUS, StatusChange);
			loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, LoadErrorHandler);
			loader.load(new URLRequest("http://utils.swfstats.com/playerlevels/rate.aspx?swfid=" + Log.SWFID + "&guid=" + Log.GUID + "&levelid=" + levelid + "&rating=" + rating + "&" + Math.random()));
			
			return true;
		}
		
		public static function RateComplete(e:Event):void
		{
			var cookie:SharedObject = SharedObject.getLocal("ratings");
			cookie.data[RateLevel] = RateAmount;
			cookie.flush();
			
			var data:XML = XML(e.target["data"]);
			var status:int = data["status"];

			RateCallback(status == 0);
			RateCallback = null;
		}
		
		private static function RateErrorHandler(e:*):void
		{
			RateCallback(false);
			RateCallback = null;
		}
		
		
		
		// loading
		public static function Load(levelid:String, callback:Function):Boolean
		{
			if(LoadCallback != null)
				return false;

			LoadCallback = callback;

			var loader:URLLoader = new URLLoader();
			loader.addEventListener(Event.COMPLETE, LoadComplete);
			loader.addEventListener(IOErrorEvent.IO_ERROR, LoadErrorHandler);
			loader.addEventListener(HTTPStatusEvent.HTTP_STATUS, StatusChange);
			loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, LoadErrorHandler);
			loader.load(new URLRequest("http://utils.swfstats.com/playerlevels/load.aspx?swfid=" + Log.SWFID + "&guid=" + Log.GUID + "&levelid=" + levelid + "&" +  Math.random()));
			
			return true;
		}
		
		private static function LoadComplete(e:Event):void
		{
			var data:XML = XML(e.target["data"]);
			var item:XML = XML(data["level"]);

			var level:PlayerLevel = new PlayerLevel();
			level.LevelId = item["levelid"];
			level.PlayerName = item["playername"];
			level.PlayerId = item["playerid"];
			level.Name = item["name"];
			level.Score = item["score"];
			level.Votes = item["votes"];
			level.Rating = item["rating"];
			level.Data = item["data"];
		
			LoadCallback(level);
			LoadCallback = null;
		}	
		
		private static function LoadErrorHandler(e:*):void
		{
			LoadCallback(null);
			LoadCallback = null;
		}		



		// listing
		public static function List(callback:Function, mode:String, page:int=1, perpage:int=20, data:Boolean=false, datemin:String="", datemax:String=""):Boolean
		{
			if(ListCallback != null)
				return false;

			ListCallback = callback;

			var loader:URLLoader = new URLLoader();
			loader.addEventListener(Event.COMPLETE, ListComplete);
			loader.addEventListener(IOErrorEvent.IO_ERROR, ListErrorHandler);
			loader.addEventListener(HTTPStatusEvent.HTTP_STATUS, StatusChange);
			loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, ListErrorHandler);
			loader.load(new URLRequest("http://utils.swfstats.com/playerlevels/list.aspx?swfid=" + Log.SWFID + "&guid=" + Log.GUID + "&mode=" + mode + "&page=" + page + "&perpage=" + perpage + "&data=" + data + "&datemin=" + datemin + "&datemax=" + datemax + "&" +  Math.random()));
			trace("http://utils.swfstats.com/playerlevels/list.aspx?swfid=" + Log.SWFID + "&guid=" + Log.GUID + "&mode=" + mode + "&page=" + page + "&perpage=" + perpage + "&data=" + data + "&datemin=" + datemin + "&datemax=" + datemax);
			
			return true;
		}
		
		private static function ListComplete(e:Event):void
		{
			var data:XML = XML(e.target["data"]);
			var entries:XMLList = data["level"];
			var levels:Array = new Array();			
			var numresults:int = data["numresults"];
			
			trace(entries);

			for each(var item:XML in entries) 
			{
				var level:PlayerLevel = new PlayerLevel();
				level.LevelId = item["levelid"];
				level.PlayerId = item["playerid"];
				level.PlayerName = item["playername"];
				level.Name = item["name"];
				level.Score = item["score"];
				level.Rating = item["rating"];
				level.Plays = item["plays"];
				level.Votes = item["votes"];

				if(item["data"])
					level.Data = item["data"];
				
				levels.push(level);
			}

			ListCallback(levels, numresults);
			ListCallback = null;
		}

		private static function ListErrorHandler(e:*):void
		{
			ListCallback(null, 0);
			ListCallback = null;
		}		
		
		
		
		// saving
		public static function Save(level:PlayerLevel, thumb:DisplayObject, callback:Function):Boolean
		{
			if(SaveCallback != null)
				return false;

			SaveCallback = callback;
			SaveLevel = level;
			
			// setup the thumbnail
			var scale:Number = 1;
			var w:int = thumb.width;
			var h:int = thumb.height;

			if(thumb.width > 100 || thumb.height > 100)
			{
				if(thumb.width >= thumb.height)
				{
					scale = 100 / thumb.width;
					w = 100;
					h = Math.ceil(scale * thumb.height);
				}
				else if(thumb.height > thumb.width)
				{
					scale = 100 / thumb.height;
					w = Math.ceil(scale * thumb.width);
					h = 100;
				}
			}
			
			var scaler:Matrix = new Matrix();
			scaler.scale(scale, scale);

			var image:BitmapData = new BitmapData(w, h, true, 0x00000000);
			image.draw(thumb, scaler, null, null, null, true);
			
			// save the level
			var postdata:URLVariables = new URLVariables();
			postdata.data = level.Data;
			postdata.image = Encode.Base64(Encode.PNG(image));
			postdata.arrp = RandomSample(image);
			postdata.hash = Encode.MD5(postdata.image + postdata.arrp);
			
			if(level.CustomData != null)
			{
				var c:int = 1;
				
				for each(var key:String in level.CustomData)
				{
					postdata["ckey" + c] = key;
					postdata["cdata" + c] = escape(level.CustomData[key]);
					c++;
				}
			}
	
			var request:URLRequest = new URLRequest("http://utils.swfstats.com/playerlevels/save.aspx?swfid=" + Log.SWFID + "&guid=" + Log.GUID + "&playerid=" + level.PlayerId + "&playername=" + escape(level.PlayerName) + "&name=" + escape(level.Name));
			request.data = postdata;
			request.method = URLRequestMethod.POST;
		
			var loader:URLLoader = new URLLoader();
			loader.dataFormat = URLLoaderDataFormat.TEXT;
			loader.addEventListener(Event.COMPLETE, SaveComplete);
			loader.addEventListener(IOErrorEvent.IO_ERROR, SaveErrorHandler);
			loader.addEventListener(HTTPStatusEvent.HTTP_STATUS, StatusChange);
			loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, SaveErrorHandler);
			loader.load(request);			
			
			return true;
		}
		
		private static function SaveComplete(e:Event):void
		{
			var data:XML = XML(e.target["data"]);
			var status:int = data["status"];		
			SaveLevel.LevelId = data["levelid"];			
			
			trace(data);
			
			SaveCallback(SaveLevel, SaveLevel.LevelId != "", status);
			SaveCallback = null;
			SaveLevel = null;
		}
		
		private static function SaveErrorHandler(e:*):void
		{
			SaveCallback(SaveLevel, false, SAVE_FAILED_GENERAL_ERROR);
			SaveCallback = null;
			SaveLevel = null;
		}
		
		private static function StatusChange(e:HTTPStatusEvent):void
		{
		}
		
		private static function RandomSample(b:BitmapData):String
		{
			var arr:Array = new Array();
			var x:int;
			var y:int;
			var c:String;
			
			while(arr.length < 10)
			{
				x = Math.random() * b.width;
				y = Math.random() * b.height;
				c = b.getPixel32(x, y).toString(16);
				
				while(c.length < 6)  
					c = "0" + c;  				
				
				arr.push(x + "/" + y + "/" + c);
			}
			
			return arr.join(",");
		}		
	}
}