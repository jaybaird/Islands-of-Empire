package lib.Playtomic
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
	import flash.xml.XMLNode;

	public final class PlayerLevels
	{		
		public function PlayerLevels() { } 
		
		// rating
		public static function Rate(levelid:String, rating:int, callback:Function = null):void
		{			
			var cookie:SharedObject = SharedObject.getLocal("ratings");

			if(cookie.data[levelid] != null)
			{
				if(callback != null)
				{
					callback({Success: false, ErrorCode:402 });
				}
				
				return;
			}
			
			if(rating < 0 || rating > 10)
			{
				if(callback != null)
				{
					callback({Success: false, ErrorCode: 401});
				}
				
				return;
			}
			
			var sendaction:URLLoader = new URLLoader();
			var handled:Boolean = false;

			if(callback != null)
			{
				var bridge:Function = function():void
				{
					if(callback == null || handled)
						return;

					handled = true;
					
					var data:XML = XML(sendaction["data"]);
					var status:int = parseInt(data["status"]);
					var errorcode:int = parseInt(data["errorcode"]);
					
					if(status == 1)
					{
						var cookie:SharedObject = SharedObject.getLocal("ratings");
						cookie.data[levelid] = rating;
						cookie.flush();
					}
					
					callback({Success: status == 1, ErrorCode: errorcode});
				}

				sendaction.addEventListener(Event.COMPLETE, bridge, false, 0, true);
			}

			var fail:Function = function():void
			{
				if(callback == null || handled)
					return;
					
				handled = true;
				callback([], {Success: false, ErrorCode: 1});
			}
			
			var httpstatusignore:Function = function():void
			{
				
			}

			sendaction.addEventListener(IOErrorEvent.IO_ERROR, fail, false, 0, true);
			sendaction.addEventListener(HTTPStatusEvent.HTTP_STATUS, httpstatusignore, false, 0, true);
			sendaction.addEventListener(SecurityErrorEvent.SECURITY_ERROR, fail, false, 0, true);
			sendaction.load(new URLRequest("http://g" + Log.GUID + ".api.playtomic.com/playerlevels/rate.aspx?swfid=" + Log.SWFID + "&levelid=" + levelid + "&rating=" + rating + "&" + Math.random()));
		}

		// loading
		public static function Load(levelid:String, callback:Function = null):void
		{
			var sendaction:URLLoader = new URLLoader();
			var handled:Boolean = false;

			if(callback != null)
			{
				var bridge:Function = function():void
				{
					if(callback == null || handled)
						return;

					handled = true;

					var data:XML = XML(sendaction["data"]);
					var status:int = parseInt(data["status"]);
					var errorcode:int = parseInt(data["errorcode"]);
					var level:PlayerLevel = new PlayerLevel();
					
					if(status == 1)
					{
						var item:XML = XML(data["level"]);
						var datestring:String = item["sdate"];				
						var year:int = int(datestring.substring(datestring.lastIndexOf("/") + 1));
						var month:int = int(datestring.substring(0, datestring.indexOf("/")));
						var day:int = int(datestring.substring(datestring.indexOf("/" ) +1).substring(0, 2));
						
						level.LevelId = item["levelid"];
						level.PlayerName = item["playername"];
						level.PlayerId = item["playerid"];
						level.Name = item["name"];
						level.Score = item["score"];
						level.Votes = item["votes"];
						level.Rating = item["rating"];
						level.Data = item["data"];
						level.SDate = new Date(year, month-1, day);
						level.RDate = item["rdate"];
									
						if(item["custom"])
						{			
							var custom:XMLList = item["custom"];
				
							level.CustomData = new Dictionary();
				
							for each(var cfield:XML in custom.children())
							{
								level.CustomData[cfield.name()] = cfield.text();
							}
						}
					}
					
					callback(level, {Success: status == 1, ErrorCode: errorcode});
				}

				sendaction.addEventListener(Event.COMPLETE, bridge, false, 0, true);
			}

			var fail:Function = function():void
			{
				if(callback == null || handled)
					return;

				handled = true;
				callback(new PlayerLevel(), {Success: false, ErrorCode: 1});
			}

			var httpstatusignore:Function = function():void
			{
				
			}

			sendaction.addEventListener(IOErrorEvent.IO_ERROR, fail, false, 0, true);
			sendaction.addEventListener(HTTPStatusEvent.HTTP_STATUS, httpstatusignore, false, 0, true);
			sendaction.addEventListener(SecurityErrorEvent.SECURITY_ERROR, fail, false, 0, true);
			sendaction.load(new URLRequest("http://g" + Log.GUID + ".api.playtomic.com/playerlevels/load.aspx?swfid=" + Log.SWFID + "&levelid=" + levelid + "&" +  Math.random()));
		}		

		// listing
		public static function List(callback:Function = null, options:Object = null):void
		{
			if(options == null)
				options = new Object();
			
			var mode:String = options.hasOwnProperty("mode") ? options["mode"] : "popular";
			var page:int = options.hasOwnProperty("page") ? options["page"] : 1;
			var perpage:int = options.hasOwnProperty("perpage") ? options["perpage"] : 20;
			var datemin:String = options.hasOwnProperty("datemin") ? options["datemin"] : "";
			var datemax:String = options.hasOwnProperty("datemax") ? options["datemax"] : "";
			var data:Boolean = options.hasOwnProperty("data") ? options["data"] : false;
			var customfilters:Object = options.hasOwnProperty("customfilters") ? options["customfilters"] : {};
			var sendaction:URLLoader = new URLLoader();
			var handled:Boolean = false;

			if(callback != null)
			{
				var bridge:Function = function():void
				{
					if(callback == null || handled)
						return;

					handled = true;
					
					var data:XML = XML(sendaction["data"]);
					var status:int = parseInt(data["status"]);
					var errorcode:int = parseInt(data["errorcode"]);
					var levels:Array = new Array();		
					var numresults:int = data["numresults"];
					
					if(status == 1)
					{
						var entries:XMLList = data["level"];
						var cfield:XML;
						var datestring:String;
						var year:int;
						var month:int;
						var day:int;			
						
						for each(var item:XML in entries) 
						{
							datestring = item["sdate"];				
							year = int(datestring.substring(datestring.lastIndexOf("/") + 1));
							month = int(datestring.substring(0, datestring.indexOf("/")));
							day = int(datestring.substring(datestring.indexOf("/" ) +1).substring(0, 2));
							
							var level:PlayerLevel = new PlayerLevel();
							level.LevelId = item["levelid"];
							level.PlayerId = item["playerid"];
							level.PlayerName = item["playername"];
							level.Name = item["name"];
							level.Score = item["score"];
							level.Rating = item["rating"];
							level.Plays = item["plays"];
							level.Votes = item["votes"];
							level.SDate = new Date(year, month-1, day);
							level.RDate = item["rdate"];
			
							if(item["data"])
							{
								level.Data = item["data"];
							}
			
							var custom:XMLList = item["custom"];
				
							if(custom != null)
							{
								level.CustomData = new Dictionary();
					
								for each(cfield in custom.children())
								{
									level.CustomData[cfield.name()] = cfield.text();
								}
							}
							
							levels.push(level);
						}
					}
		
					callback(levels, numresults, {Success: status == 1, ErrorCode: errorcode});
				}

				sendaction.addEventListener(Event.COMPLETE, bridge, false, 0, true);
			}

			var fail:Function = function():void
			{
				if(callback == null || handled)
					return;
					
				handled = true;
				callback([], 0, {Success: false, ErrorCode: 1});
			}

			var httpstatusignore:Function = function():void
			{
				
			}
			
			var postdata:URLVariables = new URLVariables();			
			var numcustomfilters:int = 0;
			
			if(customfilters != null)
			{
				for(var key:String in customfilters)
				{
					postdata["ckey" + numcustomfilters] = key;
					postdata["cdata" + numcustomfilters] = escape(customfilters[key]);
					numcustomfilters++;
				}
			}
			
			var request:URLRequest = new URLRequest("http://g" + Log.GUID + ".api.playtomic.com/playerlevels/list.aspx?swfid=" + Log.SWFID + "&mode=" + mode + "&filters=" + numcustomfilters + "&page=" + page + "&perpage=" + perpage + "&data=" + data + "&datemin=" + datemin + "&datemax=" + datemax + "&" + Math.random());
			request.data = postdata;
			request.method = URLRequestMethod.POST;

			sendaction.addEventListener(IOErrorEvent.IO_ERROR, fail, false, 0, true);
			sendaction.addEventListener(HTTPStatusEvent.HTTP_STATUS, httpstatusignore, false, 0, true);
			sendaction.addEventListener(SecurityErrorEvent.SECURITY_ERROR, fail, false, 0, true);
			sendaction.load(request);
		}
				
		// saving
		public static function Save(level:PlayerLevel, thumb:DisplayObject = null, callback:Function = null):void
		{
			// the data
			var postdata:URLVariables = new URLVariables();
			postdata.data = level.Data;
			postdata.playerid = level.PlayerId;
			postdata.playersource = level.PlayerSource;
			postdata.playername = level.PlayerName;
			postdata.name = escape(level.Name);

			if(thumb != null)
			{
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
			
				postdata.image = Encode.Base64(Encode.PNG(image));
				postdata.arrp = RandomSample(image);
				postdata.hash = Encode.MD5(postdata.image + postdata.arrp);
			}
			
			var customfields:int = 0;
			
			if(level.CustomData != null)
			{
				for(var key:String in level.CustomData)
				{
					postdata["ckey" + customfields] = key;
					postdata["cdata" + customfields] = escape(level.CustomData[key]);
					customfields++;
				}
			}

			postdata["customfields"] = customfields;
			
			// save the level
			var sendaction:URLLoader = new URLLoader();
			var handled:Boolean = false;

			if(callback != null)
			{
				var bridge:Function = function():void
				{
					if(callback == null || handled)
						return;
						
					handled = true;
					
					var data:XML = XML(sendaction["data"]);
					var status:int = parseInt(data["status"]);
					var errorcode:int = parseInt(data["errorcode"]);
					
					if(status == 1)
					{
						level.LevelId = data["levelid"];
						level.SDate = new Date();
						level.RDate = "Just now";
					}

					callback(level, {Success: status == 1, ErrorCode: errorcode});
				}

				sendaction.addEventListener(Event.COMPLETE, bridge, false, 0, true);
			}

			var fail:Function = function():void
			{
				if(callback == null || handled)
					return;
				
				handled = true;
				callback(level, {Success: false, ErrorCode: 1});
			}

			var httpstatusignore:Function = function():void
			{
			}
	
			var request:URLRequest = new URLRequest("http://g" + Log.GUID + ".api.playtomic.com/playerlevels/save.aspx?swfid=" + Log.SWFID);
			request.data = postdata;
			request.method = URLRequestMethod.POST;
		
			sendaction.dataFormat = URLLoaderDataFormat.TEXT;
			sendaction.addEventListener(IOErrorEvent.IO_ERROR, fail, false, 0, true);
			sendaction.addEventListener(HTTPStatusEvent.HTTP_STATUS, httpstatusignore, false, 0, true);
			sendaction.addEventListener(SecurityErrorEvent.SECURITY_ERROR, fail, false, 0, true);
			sendaction.load(request);			
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