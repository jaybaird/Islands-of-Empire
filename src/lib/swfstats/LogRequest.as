package lib.swfstats
{
	import flash.events.IOErrorEvent;
	import flash.events.HTTPStatusEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequest;

	public final class LogRequest
	{
		private static var Failed:int = 0;
		
		private var Data:String = "";
		private var Pieces:int;
		public var Ready:Boolean = false

		public function LogRequest()
		{
		}

		public function Queue(data:String):void
		{
			if(Failed > 3)
				return;
			
			this.Pieces++;
			this.Data += (this.Data == "" ? "" : "~") + data;

			if(this.Pieces == 8 || this.Data.length > 300)
			{
				this.Ready = true;
			}
		}

		public function Send():void
		{
			var sendaction:URLLoader = new URLLoader();
			sendaction.addEventListener(IOErrorEvent.IO_ERROR, this.IOErrorHandler);
			sendaction.addEventListener(HTTPStatusEvent.HTTP_STATUS, this.StatusChange);
			sendaction.addEventListener(SecurityErrorEvent.SECURITY_ERROR, this.SecurityErrorHandler);
			sendaction.load(new URLRequest("http://tracker.swfstats.com/Games/q.aspx?guid=" + Log.GUID + "&swfid=" + Log.SWFID + "&q=" + this.Data + "&url=" + Log.SourceUrl + "&" + Math.random() + "z"));
		}

		private function IOErrorHandler(e:IOErrorEvent):void
		{
			Failed++;
		}

		private function SecurityErrorHandler(e:SecurityErrorEvent):void
		{
		}

		private function StatusChange(e:HTTPStatusEvent):void
		{
		}
	}
}