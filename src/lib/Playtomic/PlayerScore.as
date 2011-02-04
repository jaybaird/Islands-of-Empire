package lib.Playtomic
{
	import flash.utils.Dictionary;

	public final class PlayerScore
	{
		public function PlayerScore()  { }
		
		public var Name:String;
		public var FBUserId:String;
		public var Points:Number;
		public var Website:String;
		public var SDate:Date;
		public var RDate:String;
		public var CustomData:Dictionary = new Dictionary();
	}
}