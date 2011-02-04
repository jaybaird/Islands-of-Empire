package lib.Playtomic
{
	import flash.events.IOErrorEvent;
	import flash.events.HTTPStatusEvent;
	import flash.events.SecurityErrorEvent;
	import flash.events.Event;
	import flash.net.URLRequest;
	import flash.net.URLLoader;

	public class GeoIP
	{
		public static function Lookup(callback:Function):void
		{
			var bridge:Function = function()
			{
				if(callback == null)
					return;

				var data:XML = XML(sendaction["data"]);
				var status:int = parseInt(data["status"]);
				var errorcode:int = parseInt(data["errorcode"]);
				
				if(status == 1)
				{				
					result.Code = data["location"]["code"];
					result.Name = data["location"]["name"];
				}
				
				callback(result, {Success: status == 1, ErrorCode: errorcode});
			}

			var httpstatusignore:Function = function():void
			{
				
			}
			
			var fail:Function = function()
			{
				callback(result, {Success: false, ErrorCode: 1});
			}

			var result:Object = {Code: "N/A", Name: "UNKNOWN"};
				
			var sendaction:URLLoader = new URLLoader();
			sendaction.addEventListener(Event.COMPLETE, bridge, false, 0, true);
			sendaction.addEventListener(IOErrorEvent.IO_ERROR, fail, false, 0, true);
			sendaction.addEventListener(HTTPStatusEvent.HTTP_STATUS, httpstatusignore, false, 0, true);
			sendaction.addEventListener(SecurityErrorEvent.SECURITY_ERROR, fail, false, 0, true);
			sendaction.load(new URLRequest("http://g" + Log.GUID + ".api.playtomic.com/geoip/Lookup.aspx?swfid=" + Log.SWFID + "&" + Math.random()));
		}	
	}
}