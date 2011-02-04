package lib.swfstats
{
	import flash.utils.Dictionary;

	public final class PlayerLevel
	{
		public function PlayerLevel() { }
		
		public var LevelId:String;
		public var PlayerId:int;
		public var PlayerName:String;
		public var Name:String;
		public var Data:String;
		public var Votes:int;
		public var Plays:int;
		public var Rating:Number;
		public var Score:int;
		public var CustomData:Dictionary;

		public function Thumbnail():String
		{
			return "http://utils.swfstats.com/playerlevels/thumb.aspx?levelid=" + this.LevelId;
		}
	}
}