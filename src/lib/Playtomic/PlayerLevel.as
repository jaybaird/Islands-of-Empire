package lib.Playtomic
{
	import flash.utils.Dictionary;

	public final class PlayerLevel
	{
		public function PlayerLevel() 
		{ 
			this.SDate = new Date();
			this.RDate = "Just now";
		}

		public var LevelId:String;
		public var PlayerSource:String = "";
		public var PlayerId:int = 0;
		public var PlayerName:String = "";
		public var Name:String;
		public var Data:String;
		public var Votes:int;
		public var Plays:int;
		public var Rating:Number;
		public var Score:int;
		public var SDate:Date;
		public var RDate:String;
		
		public var CustomData:Dictionary = new Dictionary();

		public function Thumbnail():String
		{
			return "http://g" + Log.GUID + ".api.playtomic.com/playerlevels/thumb.aspx?swfid=" + Log.SWFID + "&levelid=" + this.LevelId;
		}
	}
}