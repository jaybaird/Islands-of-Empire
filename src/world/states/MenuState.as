package world.states {
    import flash.net.*;
    import flash.events.*;
    import flash.display.Bitmap;
    
    import net.flashpunk.*;
    import net.flashpunk.graphics.Stamp;
    
    import gfx.*;
    import util.*;
    import util.fsm.*;
    import world.*;
    import world.menu.*;
    import components.*;
    import reactor.*;
    
    import com.bit101.components.Text;
    
    import com.gskinner.motion.*;
    import com.gskinner.motion.plugins.*;
    import com.gskinner.motion.easing.*;
    
    public class MenuState extends State {
        [Embed(source='/assets/splash/title-screen1.png')] private const TITLE_SCREEN:Class;
        [Embed(source='/assets/splash/armorlogo.png')] private const ARMOR_LOGO:Class;
        [Embed(source='/assets/splash/continue.png')] private const CONTINUE:Class;
        [Embed(source='/assets/splash/highscores.png')] private const HIGHSCORES:Class;
        [Embed(source='/assets/splash/play.png')]    private const NEW_GAME:Class;
        [Embed(source='/assets/splash/more_games.png')]    private const MORE_GAMES:Class;
        [Embed(source='/assets/sprites/goldcoin.png')] private const GOLDCOIN:Class;
        
        private static const TITLE_WIDTH:int = 720;
        
        private var _splash_img:Entity;
        private var _armor_logo:Bitmap;
        private var _new_game:MenuButton;
        private var _continue_game:MenuButton;
        private var _high_scores:MenuButton;
        private var _more_games:MenuButton;
        private var _rounded_panel:RoundedPanel;
        private var _level_txt:Text;
        private var _gold_coin:Bitmap;
        private var _gold_txt:Text;
        
        public function MenuState():void {}
        
        override public function enter():void {
            var level:int = 1;
            var gold:int = 0;
            SoundBoard.playMenuTrack();
            _splash_img = new Entity(0, 0, new Stamp(TITLE_SCREEN));
            _armor_logo = new ARMOR_LOGO();
            _new_game = MenuButton.createButton(FP.stage, 550, 420, new NEW_GAME(), newGame);
            _continue_game = MenuButton.createButton(FP.stage, 595, 470, new CONTINUE(), continueGame);
            _high_scores = MenuButton.createButton(FP.stage, 595, 515, new HIGHSCORES(), showScores);
            var data:Object = Service.loadSaveData();
            if (data != null) {
                level = data.level.number;
                gold = data.score;
            }
            _level_txt = new Text(FP.stage, 565, 495, "Level " + level + "  ");
            _gold_coin = new GOLDCOIN();
            FP.stage.addChild(_gold_coin);
            _gold_coin.x = 620, _gold_coin.y = 500;
            _gold_txt = new Text(FP.stage, 630, 495, Hud.commafy(gold));
            _gold_txt.height = _level_txt.height = 20;
            _more_games = MenuButton.createButton(FP.stage, 595, 560, new MORE_GAMES(), function():void {
                var url:String = "http://www.armorgames.com";
                var request:URLRequest = new URLRequest(url);
                try {
                    navigateToURL(request, '_blank');
                } catch (e:Error) {
                    trace("Error occurred!");
                }
            });
            
            _new_game.x = TITLE_WIDTH - _new_game.width - 15;
            _continue_game.x = TITLE_WIDTH - _continue_game.width - 15;
            _high_scores.x = TITLE_WIDTH - _high_scores.width - 15;
            _more_games.x = TITLE_WIDTH - _more_games.width - 10;
            
            var map:BaseMap = new BaseMap(Main.random(int.MAX_VALUE, int.MIN_VALUE), true);
            map.init();
            
            map.add(_splash_img);
            _rounded_panel = FP.stage.addChild(new RoundedPanel(FP.stage, 0, FP.height - 90, 10, false)) as RoundedPanel;
            _rounded_panel.width = 280, _rounded_panel.height = 80, _rounded_panel.alpha = .95, _rounded_panel.x = -10;
            _rounded_panel.addChild(_armor_logo);
            _armor_logo.x = 20, _armor_logo.y = 5;
            _rounded_panel.buttonMode = true, _rounded_panel.useHandCursor = true;
            _rounded_panel.addEventListener(MouseEvent.CLICK, function(evt:MouseEvent):void {
                var url:String = "http://www.armorgames.com";
                var request:URLRequest = new URLRequest(url);
                try {
                    navigateToURL(request, '_blank');
                } catch (e:Error) {
                    trace("Error occurred!");
                }
            });
            map.bringToFront(_splash_img);

            FP.screen = new NoiseScreen();
            FP.world = map;
        }
    
        override public function exit():void {
            FP.world.remove(_splash_img);
            FP.stage.removeChild(_new_game);
            FP.stage.removeChild(_continue_game);
            FP.stage.removeChild(_more_games);
            FP.stage.removeChild(_rounded_panel);
            FP.stage.removeChild(_level_txt);
            FP.stage.removeChild(_gold_txt);
            FP.stage.removeChild(_gold_coin);
            FP.stage.removeChild(_high_scores);
            _splash_img = null;
            _new_game = null;
            _continue_game = null;
            _high_scores = null;
        }
        
        private function newGame():void {
            Main.startNewGame();
        }
        
        private function continueGame():void {
            Main.continueGame();
        }
        
        private function showScores():void {
            Reactor.callLater(function():void {
                 Service.showScores(FP.stage);
            });
        }
    }
}