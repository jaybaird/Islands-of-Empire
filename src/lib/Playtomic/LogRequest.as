package lib.Playtomic
{
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.HTTPStatusEvent;
	import flash.events.SecurityErrorEvent;
	import flash.external.ExternalInterface;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	
	public final class LogRequest
	{
		private static var Failed:int = 0;
		private static var Pool:Array = new Array();
		
		private var Sender:URLLoader;
		private var Target:URLRequest;
		private var Data:String = "";
		private var BaseUrl:String;
		public var Ready:Boolean = false;

		public static function Create():LogRequest
		{
			var request:LogRequest = Pool.length > 0 ? Pool.pop() as LogRequest : new LogRequest();
			request.Data = "";
			request.Ready = false;
			
			return request;
		}

		public function LogRequest()
		{
			this.Sender = new URLLoader();
			this.Sender.addEventListener(Event.COMPLETE, this.Dispose, false, 0, true);
			this.Sender.addEventListener(IOErrorEvent.IO_ERROR, this.IOErrorHandler, false, 0, true);
			this.Sender.addEventListener(HTTPStatusEvent.HTTP_STATUS, this.StatusChange, false, 0, true);
			this.Sender.addEventListener(SecurityErrorEvent.SECURITY_ERROR, this.SecurityErrorHandler, false, 0, true);
					
			this.Target = new URLRequest();
			this.BaseUrl = "http://g" + Log.GUID + ".api.playtomic.com/tracker/q.aspx?swfid=" + Log.SWFID;
		}
		
		public function MassQueue(data:Array):void
		{
			if(Failed > 3)
				return;
			
			for(var i:int=data.length-1; i>-1; i--)
			{
				this.Data += (this.Data == "" ? "" : "~") + data[i];
				data.splice(i, 1);

				if(this.Data.length > 300)
				{
					var request:LogRequest = Create();
					request.MassQueue(data);
					
					this.Ready = true;
					this.Send();				
					return;
				}
			}
			
			Log.Request = this;
		}		

		public function Queue(data:String):void
		{
			if(Failed > 3)
				return;
			
			this.Data += (this.Data == "" ? "" : "~") + data;

			if(this.Data.length > 300)
			{
				this.Ready = true;
			}
		}

		public function Send():void
		{
			this.Target.url = this.BaseUrl + "&q=" + this.Data + "&url=" + Log.SourceUrl + "&" + Math.random() + "z"
			this.Sender.load(this.Target);
		}
		
		public function Dispose(e:Event = null):void
		{
			Pool.push(this);
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