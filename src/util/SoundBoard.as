package util {
    import flash.media.*;
    import flash.events.*;
    
    import net.flashpunk.*;
    import com.gskinner.motion.*;
    import com.gskinner.motion.plugins.*;
    import com.gskinner.motion.easing.*;
    
    public class SoundBoard {
        [Embed(source="/assets/sound/MainMenu.mp3")] private static const MENU_SOUND:Class;
        [Embed(source="/assets/sound/pirates_ingame.mp3")] private static const GAME_SOUND:Class;
        [Embed(source="/assets/sound/OceanAmbiance_2.mp3")] private static const ENV_SOUND:Class;
        
        [Embed(source='/assets/sound/Cannon1.mp3')] private static const CANNONFIRE1:Class;
        [Embed(source='/assets/sound/Cannon2.mp3')] private static const CANNONFIRE2:Class;
        [Embed(source='/assets/sound/Cannon3.mp3')] private static const CANNONFIRE3:Class;
        
        [Embed(source='/assets/sound/ShipDestroyed.mp3')] private static const SHIP_DESTROYED:Class;
        [Embed(source='/assets/sound/FortDestroyed.mp3')] private static const FORT_DESTROYED1:Class;
        [Embed(source='/assets/sound/FortDestroyed2.mp3')] private static const FORT_DESTROYED2:Class;
        
        [Embed(source="/assets/sound/MenuClick.mp3")] private static const MENU_CLICK:Class;
        [Embed(source='/assets/sound/ReachEnd.mp3')] private static const REACH_END:Class;
        [Embed(source='/assets/sound/PlaceWayPoint.mp3')] private static const WAYPOINT_SND:Class;
        [Embed(source="/assets/sound/Victory.mp3")] private static const VICTORY:Class;
        [Embed(source='/assets/sound/Defeat.mp3')] private static const DEFEAT:Class;
        
        [Embed(source="/assets/sound/MenuClick.mp3")] private static const snd_sfx:Class;
        private static const sfx:Sound = new snd_sfx();
        private static const silentSound:SoundTransform = new SoundTransform(0);
        
        private static var _current_loop:Sfx;
        
        private static var _sounds:Object = {};
        private static var _game_sound:Sfx;
        private static var _menu_sound:Sfx;
        private static var _env_sound:Sfx;
        private static var _cannon_sounds:Vector.<Sfx>;
        private static var _fort_explosion_sounds:Vector.<Sfx>;
        
        {
            _sounds = {
                "menuClick": new Sfx(MENU_CLICK),
                "waypoint": new Sfx(WAYPOINT_SND),
                "shipExplosion": new Sfx(SHIP_DESTROYED),
                "cannon": Vector.<Sfx>([new Sfx(CANNONFIRE1), new Sfx(CANNONFIRE2), new Sfx(CANNONFIRE3)]),
                "fortExplosion": new Sfx(FORT_DESTROYED2),
                "defeat": new Sfx(DEFEAT),
                "victory": new Sfx(VICTORY),
                "reachEnd": new Sfx(REACH_END)
            };
            _game_sound = new Sfx(GAME_SOUND);
            _menu_sound = new Sfx(MENU_SOUND);
            _env_sound = new Sfx(ENV_SOUND);
        }
        
        public static function init():void {
            playSoundSilentlyEndlessly();
        }
        
        private static function playSoundSilentlyEndlessly(evt:Event = null):void {
            sfx.play(0, 1000, silentSound);
            sfx.addEventListener(Event.SOUND_COMPLETE, playSoundSilentlyEndlessly, false, 0, true);
        }
        
        public static function playEffect(snd:String):void {
            if (_sounds[snd] is Vector.<Sfx>) {
                playRandomEffect(_sounds[snd] as Vector.<Sfx>);
            } else {
                (_sounds[snd] as Sfx).play(FP.volume);
            }
        }
        
        private static function playRandomEffect(sounds:Vector.<Sfx>):void {
            sounds[Main.random(_sounds.length-1, 0)].play(FP.volume);
        }
        
        public static function playMenuTrack():void {
            _menu_sound.loop(0);
            new GTween(_menu_sound, 1.5, {'volume': 1}, {'ease': Linear.easeNone});
        }
        
        public static function playGameTrack():void {
            _game_sound.loop(0);
            new GTween(_menu_sound, .3, {'volume': FP.volume}, {
                'ease':Linear.easeNone,
                'onComplete': function():void {
                    _menu_sound.stop();
                    _env_sound.loop(.5);
                }
            });
            new GTween(_game_sound, .3, {'volume': FP.volume}, {'ease':Linear.easeNone});
        }
        
        public static function muteGameTrack(callback:Function=null):void {
            var volume:Number = 0;
            if (_game_sound.volume == 0) volume = 1.0
            new GTween(_game_sound, .3, {'volume': volume}, {'ease':Linear.easeNone, 'onComplete':callback});
        }
        
        public static function mute():void {
            FP.volume = (FP.volume == 1.0) ? 0 : 1;
        }
    }
}