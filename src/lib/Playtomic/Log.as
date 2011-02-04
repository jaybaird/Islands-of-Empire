package lib.Playtomic
{
	import flash.events.TimerEvent;
	import flash.external.ExternalInterface;
	import flash.net.SharedObject;
	import flash.system.Security;
	import flash.utils.Timer;

	public final class Log
	{
		// API settings
		public static var Enabled:Boolean = false;
		public static var Queue:Boolean = true;
		
		// SWF settings
		public static var SWFID:int = 0;
		public static var GUID:String = "";
		public static var SourceUrl:String;
		public static var BaseUrl:String;
	
		// play timer, goal tracking etc
		public static var Cookie:SharedObject;
		public static var Request:LogRequest;
		private static const PingF:Timer = new Timer(60000);
		private static const PingR:Timer = new Timer(30000);
		private static var FirstPing:Boolean = true;
		private static var Pings:int = 0;
		private static var Plays:int = 0;
		private static var HighestGoal:int = 0;		
		
		private static var Frozen:Boolean = false;
		private static var FrozenQueue:Array = new Array();

		// unique, logged metrics
		private static var Customs:Array = new Array();
		private static var LevelCounters:Array = new Array();
		private static var LevelAverages:Array = new Array();
		private static var LevelRangeds:Array = new Array();


		// ------------------------------------------------------------------------------
		// View
		// Logs a view and initialises the SWFStats API
		// ------------------------------------------------------------------------------
		public static function View(swfid:int = 0, guid:String = "", defaulturl:String = ""):void
		{
			if(SWFID > 0)
				return;

			SWFID = swfid;
			GUID = guid;
			Enabled = true;

			if((SWFID == 0 || GUID == ""))
			{
				Enabled = false;
				return;
			}

			// Check the URL is http		
			if(defaulturl.indexOf("http://") != 0 && Security.sandboxType != "localWithNetwork" && Security.sandboxType != "localTrusted")
			{
				Enabled = false;
				return;
			}
			
			SourceUrl = GetUrl(defaulturl);

			if(SourceUrl == null || SourceUrl == "")
			{
				Enabled = false;
				return;
			}
			
			// Load the security context
			Security.allowDomain("http://g" + Log.GUID + ".api.playtomic.com/");
			Security.allowInsecureDomain("http://g" + Log.GUID + ".api.playtomic.com/");
			Security.loadPolicyFile("http://g" + Log.GUID + ".api.playtomic.com/crossdomain.xml");
		
			// Log the view (first or repeat visitor)
			Request = LogRequest.Create();
			Cookie = SharedObject.getLocal("playtomic");
			
			var views:int = GetCookie("views");
			views++;
			SaveCookie("views", views);

			Send("v/" + views, true);

			// Start the play timer
			PingF.addEventListener(TimerEvent.TIMER, PingServer);
			PingF.start();
		}

		// ------------------------------------------------------------------------------
		// Play
		// Logs a play.
		// ------------------------------------------------------------------------------
		public static function Play():void
		{						
			if(!Enabled)
				return;

			LevelCounters = new Array();
			LevelAverages = new Array();
			LevelRangeds = new Array();
				
			Plays++;
			Send("p/" + Plays);
		}

		// ------------------------------------------------------------------------------
		// Ping
		// Tracks how long the player's session lasts.  First ping is at 60 seconds after
		// which it occurs every 30 seconds.
		// ------------------------------------------------------------------------------
		private static function PingServer(...args):void
		{			
			if(!Enabled)
				return;
				
			Pings++;
			
			Send("t/" + (FirstPing ? "y" : "n") + "/" + Pings, true);
				
			if(FirstPing)
			{
				PingF.stop();

				PingR.addEventListener(TimerEvent.TIMER, PingServer);
				PingR.start();

				FirstPing = false;
			}
		}
		
		// ------------------------------------------------------------------------------
		// CustomMetric
		// Logs a custom metric event.
		// ------------------------------------------------------------------------------
		public static function CustomMetric(name:String, group:String = null, unique:Boolean = false):void
		{		
			if(!Enabled)
				return;

			if(group == null)
				group = "";

			if(unique)
			{
				if(Customs.indexOf(name) > -1)
					return;

				Customs.push(name);
			}
			
			Send("c/" + Clean(name) + "/" + Clean(group));
		}

		// ------------------------------------------------------------------------------
		// LevelCounterMetric, LevelRangedMetric, LevelAverageMetric
		// Logs an event for each level metric type.
		// ------------------------------------------------------------------------------
		public static function LevelCounterMetric(name:String, level:*, unique:Boolean = false):void
		{		
			if(!Enabled)
				return;

			if(unique)
			{
				if(LevelCounters.indexOf(name) > -1)
					return;

				LevelCounters.push(name);
			}
			
			Send("lc/" + Clean(name) + "/" + Clean(level));
		}
		
		public static function LevelRangedMetric(name:String, level:*, value:int, unique:Boolean = false):void
		{			
			if(!Enabled)
				return;

			if(unique)
			{
				if(LevelRangeds.indexOf(name) > -1)
					return;

				LevelRangeds.push(name);
			}
			
			Send("lr/" + Clean(name) + "/" + Clean(level) + "/" + value);
		}

		public static function LevelAverageMetric(name:String, level:*, value:int, unique:Boolean = false):void
		{
			if(!Enabled)
				return;

			if(unique)
			{
				if(LevelAverages.indexOf(name) > -1)
					return;

				LevelAverages.push(name);
			}
			
			Send("la/" + Clean(name) + "/" + Clean(level) + "/" + value);
		}
		
		// ------------------------------------------------------------------------------
		// Freezing
		// Pauses / unpauses the API
		// ------------------------------------------------------------------------------
		public static function Freeze():void
		{
			Frozen = true;
		}

		public static function UnFreeze():void
		{
			Frozen = false;
			Request.MassQueue(FrozenQueue);
		}

		public static function ForceSend():void
		{
			Request.Send();
		}
		
		// ------------------------------------------------------------------------------
		// Send
		// Creates and sends the url requests to the tracking service.
		// ------------------------------------------------------------------------------
		private static function Send(s:String, view:Boolean = false):void
		{
			if(Frozen)
			{
				FrozenQueue.push(s);
				return;
			}
			
			Request.Queue(s);

			if(Request.Ready || view || !Queue)
			{
				Request.Send();
				Request = LogRequest.Create();
			}
		}
		
		private static function Clean(s:String):String
		{
			return escape(s.replace("/", "\\").replace("~", "-"));
		}
	
		// ------------------------------------------------------------------------------
		// GetCookie and SetCookie
		// Records or retrieves data like how many times the person has played your
		// game.
		// ------------------------------------------------------------------------------
		private static function GetCookie(n:String):int
		{
			if(Cookie.data[n] == undefined)
			{
				return 0;
			}
			else
			{
				return int(Cookie.data[n]);
			}
		}
		
		private static function SaveCookie(n:String, v:int):void
		{
			var cookie:SharedObject = SharedObject.getLocal("swfstats");
			cookie.data[n] = v.toString();
			cookie.flush();
		}	

		// ------------------------------------------------------------------------------
		// GetUrl
		// Tries to identify the actual page url, and if it's unable to it reverts to 
		// the default url you passed the View method.  If you're testing the game it
		// should revert to http://local-testing/.
		// ------------------------------------------------------------------------------
		private static function GetUrl(defaulturl:String):String
		{
			var url:String;
			
			if(ExternalInterface.available)
			{
				try
				{
					url = String(ExternalInterface.call("window.location.href.toString"));
				}
				catch(s:Error)
				{
					url = defaulturl;
				}
			}
			else if(defaulturl.indexOf("http://") == 0)
			{
				url = defaulturl;
			}

			if(url == null  || url == "" || url == "null")
			{
				if(Security.sandboxType == "localWithNetwork" || Security.sandboxType == "localTrusted")
				{
					url = "http://local-testing/";
				}
				else
				{
					url = null;
				}
			}

			return escape(url);
		}
	}
}