package lib.Playtomic
{
	import flash.events.IOErrorEvent;
	import flash.events.HTTPStatusEvent;
	import flash.events.SecurityErrorEvent;
	import flash.events.Event;
	import flash.net.URLRequest;
	import flash.net.URLLoader;
	import flash.net.URLVariables;
	import flash.net.URLRequestMethod;
	import flash.utils.Dictionary;

	public class Leaderboards
	{
		public static function List(table:String, callback:Function, options:Object = null):void
		{
			if(options == null)
				options = new Object();

			var global:Boolean = options.hasOwnProperty("global") ? options["global"] : true;
			var highest:Boolean = options.hasOwnProperty("highest") ? options["highest"] : true;
			var mode:String = options.hasOwnProperty("mode") ? options["mode"] : "alltime";
			var customfilters:Object = options.hasOwnProperty("customfilters") ? options["customfilters"] : {};
			var page:int = options.hasOwnProperty("page") ? options["page"] : 1;
			var perpage:int = options.hasOwnProperty("perpage") ? options["perpage"] : 20;
			var sendaction:URLLoader = new URLLoader();
			var handled:Boolean = false;

			if(callback != null)
			{
				var bridge:Function = function():void
				{	
					if(callback == null || handled)
						return;
						
					handled = true;
					ProcessScores(sendaction, callback);
				}

				sendaction.addEventListener(Event.COMPLETE, bridge);
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
						
			var request:URLRequest = new URLRequest("http://g" + Log.GUID + ".api.playtomic.com/leaderboards/list.aspx?swfid=" + Log.SWFID + "&table=" + table + "&mode=" + mode + "&filters=" + numcustomfilters + "&url=" + (global || Log.SourceUrl == null ? "global" : Log.SourceUrl) + "&highest=" + (highest ? "y" : "n") + "&page=" + page + "&perpage=" + perpage + "&" + Math.random());
			request.data = postdata;
			request.method = URLRequestMethod.POST;			
			
			sendaction.addEventListener(IOErrorEvent.IO_ERROR, fail, false, 0, true);
			sendaction.addEventListener(HTTPStatusEvent.HTTP_STATUS, httpstatusignore, false, 0, true);
			sendaction.addEventListener(SecurityErrorEvent.SECURITY_ERROR, fail, false, 0, true);
			sendaction.load(request);
		}

		public static function ListFB(table:String, callback:Function, options:Object = null):void
		{
			if(options == null)
				options = new Object();
			
			var global:Boolean = options.hasOwnProperty("global") ? options["global"] : true;
			var highest:Boolean = options.hasOwnProperty("highest") ? options["highest"] : true;
			var friendslist:Array = options.hasOwnProperty("friendslist") ? options["friendslist"] : new Array();
			var mode:String = options.hasOwnProperty("mode") ? options["mode"] : "alltime";
			var customfilters:Object = options.hasOwnProperty("customfilters") ? options["customfilters"] : {};
			var page:int = options.hasOwnProperty("page") ? options["page"] : 1;
			var perpage:int = options.hasOwnProperty("perpage") ? options["perpage"] : 20;
			var sendaction:URLLoader = new URLLoader();
			var handled:Boolean = false;

			if(callback != null)
			{
				var bridge:Function = function():void
				{	
					if(callback == null || handled)
						return;
						
					handled = true;
					ProcessScores(sendaction, callback);
				}

				sendaction.addEventListener(Event.COMPLETE, bridge);
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
			postdata["friendslist"] = friendslist.join(",");
			
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
			
			var request:URLRequest = new URLRequest("http://g" + Log.GUID + ".api.playtomic.com/leaderboards/listfb.aspx?swfid=" + Log.SWFID + "&table=" + table + "&mode=" + mode + "&filters=" + numcustomfilters + "&url=" + (global || Log.SourceUrl == null ? "global" : Log.SourceUrl) + "&highest=" + (highest ? "y" : "n") + "&page=" + page + "&perpage=" + perpage + "&" + Math.random());
			request.data = postdata;
			request.method = URLRequestMethod.POST;

			sendaction.addEventListener(IOErrorEvent.IO_ERROR, fail, false, 0, true);
			sendaction.addEventListener(HTTPStatusEvent.HTTP_STATUS, httpstatusignore, false, 0, true);
			sendaction.addEventListener(SecurityErrorEvent.SECURITY_ERROR, fail, false, 0, true);
			sendaction.load(request);
		}

		public static function Save(score:PlayerScore, table:String, callback:Function = null, options:Object = null)
		{
			if(options == null)
				options = new Object();
				
			var facebook:Boolean = options.hasOwnProperty("facebook") ? options["facebook"] : false;
			var allowduplicates:Boolean = options.hasOwnProperty("allowduplicates") ? options["allowduplicates"] : false;
			var highest:Boolean = options.hasOwnProperty("highest") ? options["highest"] : true;
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
					
					if(status == 1)
					{					
						score.SDate = new Date();
						score.RDate = "Just now";
					}
					
					callback(score, {Success: status == 1, ErrorCode: parseInt(data["errorcode"])});
				}

				sendaction.addEventListener(Event.COMPLETE, bridge);
			}

			var fail:Function = function():void
			{
				if(callback == null || handled)
					return;
										
				handled = true;
				callback(score, {Success: false, ErrorCode: 1});
			}
			
			var httpstatusignore:Function = function():void
			{
				
			}

			// save the score
			var s:String = score.Points.toString();
			
			if(s.indexOf(".") > -1)
				s = s.substring(0, s.indexOf("."));
			
			var postdata:URLVariables = new URLVariables();
			postdata["table"] = escape(table);
			postdata["highest"] = highest;
			postdata["name"] = escape(score.Name);
			postdata["points"] = s;
			postdata["allowduplicates"] = allowduplicates ? "y" : "n";
			postdata["auth"] = Encode.MD5(Log.SourceUrl + s);
			postdata["fb"] = facebook ? "y" : "n";
			postdata["fbuserid"] = score.FBUserId;
			
			var customfields:int = 0;
			
			if(score.CustomData != null)
			{
				for(var key:String in score.CustomData)
				{
					postdata["ckey" + customfields] = key;
					postdata["cdata" + customfields] = escape(score.CustomData[key]);
					customfields++;
				}
			}
			
			postdata["customfields"] = customfields;

			var request:URLRequest = new URLRequest("http://g" + Log.GUID + ".api.playtomic.com/leaderboards/save.aspx?swfid=" + Log.SWFID + "&url=" + Log.SourceUrl + "&r=" + Math.random());
			request.data = postdata;
			request.method = URLRequestMethod.POST;

			sendaction.addEventListener(IOErrorEvent.IO_ERROR, fail, false, 0, true);
			sendaction.addEventListener(HTTPStatusEvent.HTTP_STATUS, httpstatusignore, false, 0, true);
			sendaction.addEventListener(SecurityErrorEvent.SECURITY_ERROR, fail, false, 0, true);
			sendaction.load(request);
		}

		private static function ProcessScores(loader:URLLoader, callback:Function):void
		{			
			var data:XML = XML(loader["data"]);
			var status:int = parseInt(data["status"]);
			var errorcode:int = parseInt(data["errorcode"]);
			var numscores:int = parseInt(data["numscores"]);
			var results:Array = new Array();
			
			if(status == 1)
			{
				var entries:XMLList = data["score"];
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
					
					var score:PlayerScore = new PlayerScore();
					score.SDate = new Date(year, month-1, day);
					score.RDate = item["rdate"];
					score.Name = item["name"];
					score.Points = item["points"];
					score.Website = item["website"];
					
					if(item["custom"])
					{			
						var custom:XMLList = item["custom"];
			
						score.CustomData = new Dictionary();
			
						for each(var cfield:XML in custom.children())
						{
							score.CustomData[cfield.name()] = cfield.text();
						}
					}
					
					results.push(score);
				}
			}
			
			callback(results, numscores, {Success: status == 1, ErrorCode: errorcode});
		}
	}
}