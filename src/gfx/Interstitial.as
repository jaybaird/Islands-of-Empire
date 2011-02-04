package gfx {
    import flash.text.*;
    import flash.geom.*;
    import flash.events.*;
    import flash.display.*;
    
    import net.flashpunk.*;
    import net.flashpunk.graphics.Spritemap;
    import com.bit101.components.*;
    import org.as3commons.lang.ObjectUtils;
    
    import com.gskinner.motion.*;
    import com.gskinner.motion.plugins.*;
    import com.gskinner.motion.easing.*;
    
    import util.*;
    import components.*;
    import world.Map;
    import world.entities.*;
    
    public class Interstitial extends Sprite {
        [Embed(source='/assets/splash/round_won.png')] private const SUCCESS:Class;
        [Embed(source='/assets/splash/round_lost.png')] private const FAILURE:Class;
        [Embed(source='/assets/masks/skull-n-crossbones.png')] private const SKULLNBONES:Class;
        [Embed(source='/assets/sprites/goldcoin.png')] private const GOLDCOIN:Class;
        [Embed(source='/assets/sprites/greencross.png')] private const GREENCROSS:Class;
        
        private var _status:Boolean;
        private var _heal_ships:Boolean;
        private var _ship_statuses:Vector.<ShipStatus>;
        private var _repair_text:Text;
        
        public function Interstitial(status:Boolean):void {
            super();
            _status = status;
            _ship_statuses = new Vector.<ShipStatus>();
            addEventListener(Event.ADDED_TO_STAGE, init);
        }
        
        private function init(evt:Event):void {
            removeEventListener(Event.ADDED_TO_STAGE, init);
            var bmp:Bitmap = (_status) ? new SUCCESS() : new FAILURE();
            addChild(bmp);
            if (_status) success();
            else failure();
        }
        
        public function get repairText():Text { return _repair_text; }
        
        private function sortShipsByDamage(a:Ship, b:Ship):int {
            if (!a || !b) return 0;
            if (a is Airship || b is Airship) return -1;
            return (a.health < b.health) ? -1 : (a.health == b.health) ? 0 : 1;
        }
        
        private function removeStatuses():void {
            for (var i:int=0; i < _ship_statuses.length; i++) {
                if (contains(_ship_statuses[i])) removeChild(_ship_statuses[i]);
            }
        }
        
        private function buildStatuses():void {
            var idx:int = 0;
            var ships:Vector.<Ship> = Main.ships.slice(1).sort(sortShipsByDamage);
            ships.unshift(Main.ships[0]);
            for (var i:int=0; i < ships.length; i++) {
                var ship_sprite:BitmapData;
                if (i == 0 || ships[i] == null) {
                    ship_sprite = new BitmapData(32, 32, true, 0);
                } else {
                    ship_sprite = new BitmapData(24, 24, true, 0);
                }
                var sprite:BitmapData;
                var ship_status:ShipStatus;
                if (ships[i] == null) {
                    sprite = new SKULLNBONES().bitmapData;
                } else {
                    sprite = (ships[i].graphic as Spritemap).source;
                }
                ship_sprite.copyPixels(sprite, ship_sprite.rect, sprite.rect.topLeft);
                ship_status = new ShipStatus(ships[i], ship_sprite);
                if (i == 0) {
                    ship_status.x = 355 + (42), ship_status.y = 320;
                } else {
                    if (ships[i] == null) {
                        if (i < 11) {
                            ship_status.x = 365 + (30 * idx) - 2, ship_status.y = 360 - 5;
                        } else {
                            ship_status.x = 365 + (30 * (idx-10)) - 2, ship_status.y = 395 - 5;
                        }
                    } else {
                        if (i < 11) {
                            ship_status.x = 365 + (30 * idx), ship_status.y = 360;
                        } else {
                            ship_status.x = 365 + (30 * (idx-10)), ship_status.y = 395;
                        }
                    }
                }
                idx++;
                addChild(ship_status);
                _ship_statuses.push(ship_status);
            }
        }
        
        private function getAddedCost(n:Number):Number {
            if (Main.level.number < 3) return n;
            if (Main.level.number < 6) return n - (n * 0.03);
            if (Main.level.number < 9) return n - (n * 0.06);
            if (Main.level.number <= 12) return n - (n * 0.1);
            return n;
        }
        
        private function success():void {
            var status:Text = new Text(this, 395, 200, "Level " + Main.level.number.toString() + " - Ship Status and Repair");
            var repair_slot:RoundedPanel = new RoundedPanel(this, 397, 225, 20);
            repair_slot.width = repair_slot.height = 75;
            repair_slot.name = "repair_slot";
            var bmp:Bitmap = new GOLDCOIN();
            bmp.x = 500, bmp.y = 230;
            addChild(bmp);
            var cross:Bitmap = new GREENCROSS();
            cross.name = 'repair_slot';
            repair_slot.addChild(cross);
            _repair_text = new Text(this, 510, 225, "Gold: " + Hud.commafy(int(Math.round(Main.currentScore))));
            var repair_explanation:Text = new Text(this, 497, 245, "Drag a damaged ship to the repair bay at left to start repairs. Repair costs come out of your gold supply.");
            var repair_all:PushButton = new PushButton(this, 497, 315, "Repair All", function(evt:Event):void {                
                for (var i:int=0; i < Main.ships.length; i++) {
                    if (Main.ships[i] == null) continue;
                    var diff:int = getAddedCost(FP.getClass(Main.ships[i]).TOTAL_HEALTH - Main.ships[i].health);
                    if (Main.currentScore > diff) {
                        _ship_statuses[i].healShip(true);
                    }
                }
            });
            buildStatuses();
            addUpgrades();
            
            var nextLevel:PushButton = new PushButton(this, 0, 520, "Next Level >>", function(evt:MouseEvent):void {
                if(_heal_ships) {
                    for (var i:int=0; i < Main.TOTAL_SHIPS; i++) {
                        if (Main.ships[i] == null) continue;
                        Main.ships[i].totalHealth = FP.getClass(Main.ships[i]).TOTAL_HEALTH + 100;
                        Main.ships[i].health = FP.getClass(Main.ships[i]).TOTAL_HEALTH;
                    }
                    removeStatuses();
                    buildStatuses();
                }
                Main.nextLevel.dispatch();
            });
            var resetLevel:PushButton = new PushButton(this, 0, 520, "Restart Level", function(evt:MouseEvent):void {
                trace("restart");
                Hud.instance.restartLevel.dispatch();
            });
            var width:int = nextLevel.width + resetLevel.width;
            nextLevel.x = 540 - width/2;
            resetLevel.x = nextLevel.x + nextLevel.width + 10;
        }
        
        private function addUpgrades():void {
            var txt:Text = new Text(this, 392, 400, "Upgrade Your Fleet");
            var cannon_check:CheckBox = new CheckBox(this, 395, 430, "Upgraded Cannon", function(evt:Event):void {
                if (cannon_check.selected) {
                    if ((Main.currentScore - Main.upgradeCost('cannon')) >= 0) {
                        Main.upgrades.cannon = true;
                        SoundBoard.playEffect("waypoint");
                        new GTween(Main, .3, {'currentScore':Main.currentScore-Main.upgradeCost('cannon')}, {'ease':Linear.easeNone, 'onChange':function(t:GTween):void {
                            repairText.text = "Gold: " + Hud.commafy(int(Math.round(Main.currentScore)));
                            Hud.instance.score.text = Hud.commafy(int(Math.round(Main.currentScore)));
                        }});
                    } else {
                        cannon_check.selected = false;
                        Hud.instance.showMessage("You need more gold to purchase this upgrade.");
                    }
                } else {
                    Main.upgrades.cannon = false;
                    SoundBoard.playEffect("waypoint");
                    new GTween(Main, .3, {'currentScore':Main.currentScore+Main.upgradeCost('sails')}, {'ease':Linear.easeNone, 'onChange':function(t:GTween):void {
                        repairText.text = "Gold: " + Hud.commafy(int(Math.round(Main.currentScore)));
                        Hud.instance.score.text = Hud.commafy(int(Math.round(Main.currentScore)));
                    }});
                }
            });
            var cannon_coin:Bitmap = new GOLDCOIN();
            cannon_coin.x = 408, cannon_coin.y = 450;
            var cannon_txt:Text = new Text(this, 418, 445, Hud.commafy(Main.upgradeCost('cannon')));
            addChild(cannon_coin);
            
            var sail_check:CheckBox = new CheckBox(this, 505, 430, "Cotton Sails", function(evt:Event):void {
                if (sail_check.selected) {
                    if ((Main.currentScore - Main.upgradeCost('sails')) >= 0) {
                        Main.upgrades.sails = true;
                        SoundBoard.playEffect("waypoint");
                        new GTween(Main, .3, {'currentScore':Main.currentScore-Main.upgradeCost('sails')}, {'ease':Linear.easeNone, 'onChange':function(t:GTween):void {
                            repairText.text = "Gold: " + Hud.commafy(int(Math.round(Main.currentScore)));
                            Hud.instance.score.text = Hud.commafy(int(Math.round(Main.currentScore)));
                        }});
                    } else {
                        sail_check.selected = false;
                        Hud.instance.showMessage("You need more gold to purchase this upgrade.");
                    }
                } else {
                    Main.upgrades.sails = false;
                    SoundBoard.playEffect("waypoint");
                    new GTween(Main, .3, {'currentScore':Main.currentScore+Main.upgradeCost('sails')}, {'ease':Linear.easeNone, 'onChange':function(t:GTween):void {
                        repairText.text = "Gold: " + Hud.commafy(int(Math.round(Main.currentScore)));
                        Hud.instance.score.text = Hud.commafy(int(Math.round(Main.currentScore)));
                    }});
                }
            });
            var sail_coin:Bitmap = new GOLDCOIN();
            sail_coin.x = 518, sail_coin.y = 450;
            var sail_txt:Text = new Text(this, 528, 445, Hud.commafy(Main.upgradeCost('sails')));
            addChild(sail_coin);
            
            var armor_check:CheckBox = new CheckBox(this, 395, 470, "Armor Plating", function(evt:Event):void {
                if (armor_check.selected) {
                    if ((Main.currentScore - Main.upgradeCost('armorPlating')) >= 0) {
                        Main.upgrades.armorPlating = true;
                        SoundBoard.playEffect("waypoint");
                        new GTween(Main, .3, {'currentScore':Main.currentScore-Main.upgradeCost('armorPlating')}, {'ease':Linear.easeNone, 'onChange':function(t:GTween):void {
                            repairText.text = "Gold: " + Hud.commafy(int(Math.round(Main.currentScore)));
                            Hud.instance.score.text = Hud.commafy(int(Math.round(Main.currentScore)));
                        }});
                        _heal_ships = true;
                    } else {
                        _heal_ships = false;
                        armor_check.selected = false;
                        Hud.instance.showMessage("You need more gold to purchase this upgrade.");
                    }
                } else {
                    Main.upgrades.armorPlating = false;
                    SoundBoard.playEffect("waypoint");
                    new GTween(Main, .3, {'currentScore':Main.currentScore+Main.upgradeCost('armorPlating')}, {'ease':Linear.easeNone, 'onChange':function(t:GTween):void {
                        repairText.text = "Gold: " + Hud.commafy(int(Math.round(Main.currentScore)));
                        Hud.instance.score.text = Hud.commafy(int(Math.round(Main.currentScore)));
                    }});
                }
            });
            var armor_coin:Bitmap = new GOLDCOIN();
            armor_coin.x = 408, armor_coin.y = 490;
            var armor_txt:Text = new Text(this, 418, 485, Hud.commafy(Main.upgradeCost('armorPlating')));
            addChild(armor_coin);
            
            var grape_check:CheckBox = new CheckBox(this, 505, 470, "Grape Shot", function(evt:Event):void {
                if (grape_check.selected) {
                    if ((Main.currentScore - Main.upgradeCost('grapeShot')) >= 0) {
                        Main.upgrades.grapeShot = true;
                        SoundBoard.playEffect("waypoint");
                        new GTween(Main, .3, {'currentScore':Main.currentScore-Main.upgradeCost('grapeShot')}, {'ease':Linear.easeNone, 'onChange':function(t:GTween):void {
                            repairText.text = "Gold: " + Hud.commafy(int(Math.round(Main.currentScore)));
                            Hud.instance.score.text = Hud.commafy(int(Math.round(Main.currentScore)));
                        }});
                    } else {
                        grape_check.selected = false;
                        Hud.instance.showMessage("You need more gold to purchase this upgrade.");
                    }
                } else {
                    Main.upgrades.grapeShot = false;
                    SoundBoard.playEffect("waypoint");
                    new GTween(Main, .3, {'currentScore':Main.currentScore+Main.upgradeCost('grapeShot')}, {'ease':Linear.easeNone, 'onChange':function(t:GTween):void {
                        repairText.text = "Gold: " + Hud.commafy(int(Math.round(Main.currentScore)));
                        Hud.instance.score.text = Hud.commafy(int(Math.round(Main.currentScore)));
                    }});
                }
            });
            var grape_coin:Bitmap = new GOLDCOIN();
            grape_coin.x = 518, grape_coin.y = 490;
            var grape_txt:Text = new Text(this, 528, 485, Hud.commafy(Main.upgradeCost('grapeShot')));
            addChild(grape_coin);
            
            if (Main.upgrades.cannon) {
                cannon_check.enabled = false;
                cannon_check.selected = true;
            }
            if (Main.upgrades.sails) {
                sail_check.enabled = false;
                sail_check.selected = true;
            }
            if (Main.upgrades.grapeShot) {
                grape_check.enabled = false;
                grape_check.selected = true;
            }
            if (Main.upgrades.armorPlating) {
                armor_check.enabled = false;
                armor_check.selected = true;
            }
            createToolTip(Vector.<DisplayObject>([cannon_check]), "Upgraded Cannon", "This cannon never misses! Enjoy improved range, damage and accuracy.");
            createToolTip(Vector.<DisplayObject>([armor_check]), "Armor Plating", "Increases your total health by 100! Upgrading also heals all your ships!");
            createToolTip(Vector.<DisplayObject>([grape_check]), "Grape Shot", "Does up to 30% extra damage to enemy ships.");
            createToolTip(Vector.<DisplayObject>([sail_check]), "Cotton Sails", "Improvements in sail technology allow your ships to move faster through the water.");
        }
        
        private function createToolTip(objs:Vector.<DisplayObject>, title:String="", txt:String="", align:String="center"):void {
            var tt:ToolTip = new ToolTip();
            tt.delay = 500, tt.hookSize = 5;
            tt.titleEmbed = tt.contentEmbed = true;
            tt.titleFormat = tt.contentFormat = new TextFormat(Style.fontName, Style.fontSize, Style.LABEL_TEXT);
            tt.hook = true, tt.align = align;
            tt.colors = 0x000000, tt.bgAlpha = 1;
            tt.borderSize = 1, tt.border = 0xacacac;
            tt.cornerRadius = 10, tt.minY = 0;;
            if (txt == "") {
                tt.cornerRadius = 5;
                tt.autoSize = true;
            } else {
                tt.cornerRadius = 10
            }
            for (var i:int=0; i < objs.length; i++) {
                var obj:DisplayObject = objs[i];
                tt.tipWidth = int(obj.width * 2);
                obj.addEventListener(MouseEvent.ROLL_OVER, function(evt:MouseEvent):void {
                    tt.show(obj, title, txt);
                });
            }
        }
        
        private function failure():void {
            var resetLevel:PushButton = new PushButton(this, 0, 350, "Restart Level", function(evt:MouseEvent):void {
                trace("restart");
                Hud.instance.restartLevel.dispatch();
            });
            resetLevel.x = 540 - resetLevel.width/2;
        }
    }
}

import flash.geom.*;
import flash.events.*;
import flash.display.*;

import com.gskinner.motion.*;
import com.gskinner.motion.plugins.*;
import com.gskinner.motion.easing.*;

import net.flashpunk.FP;
import net.flashpunk.graphics.Spritemap;

import gfx.*;
import util.*;
import components.*;
import world.entities.*;

internal class ShipStatus extends Sprite {
    private var _life_bar:BitmapData;
    private var _ship_bmp:Bitmap;
    private var _ship:Ship;
    private var _start_point:Point;
    
    public function ShipStatus(ship:Ship, bmpd:BitmapData):void {
        _ship_bmp = new Bitmap(bmpd);
        _ship = ship;
        _life_bar = new BitmapData(20, 2, false, 0xacacac);
        addEventListener(Event.ADDED_TO_STAGE, init);
        if (_ship) {
            addEventListener(MouseEvent.MOUSE_DOWN, dragging);
            addEventListener(MouseEvent.ROLL_OVER, showStats);
        }
    }
    
    private function showStats(evt:MouseEvent):void {
        if(_ship) _ship.showStats(this);
    }
    
    private function dragging(evt:MouseEvent):void {
        startDrag();
        addEventListener(MouseEvent.MOUSE_UP, stopDragging);
    }
    
    private function stopDragging(evt:MouseEvent):void {
        stopDrag();
        if (dropTarget != null && 
           (dropTarget.name == 'repair_slot' ||
            dropTarget.parent.name == 'repair_slot' || 
            dropTarget.parent.parent.name == 'repair_slot')) {
            trace("healing ship!");
            healShip();
            if (_ship is Airship) {
                x = dropTarget.parent.x + 21, y = dropTarget.parent.y + 21;
            } else {
                x = dropTarget.parent.x + 25, y = dropTarget.parent.y + 25;
            }
        } else {
            new GTween(this, .3, {'x':_start_point.x, 'y':_start_point.y}, {'ease':Linear.easeNone});
        }
    }
    
    private function getAddedCost(n:Number):Number {
        if (Main.level.number < 3) return n;
        if (Main.level.number < 6) return n - (n * 0.03);
        if (Main.level.number < 9) return n - (n * 0.06);
        if (Main.level.number <= 12) return n - (n * 0.1);
        return n;
    }
    
    public function healShip(heal_all:Boolean=false):void {
        var heal:int = FP.getClass(_ship).TOTAL_HEALTH - _ship.health;
        var diff:int = getAddedCost(heal);
        trace("heal:", heal);
        trace("diff:", diff);
        if (Main.currentScore == 0 || diff == 0) {
            if (diff == 0 && !heal_all) Hud.instance.showMessage("Ship is 100% and battle ready!");
            else if (Main.currentScore == 0) Hud.instance.showMessage("Not enough gold!");
            new GTween(this, .3, {'x':_start_point.x, 'y':_start_point.y}, {'ease':Linear.easeNone});
        } else {
            var self:Sprite = this;
            if (diff > Main.currentScore) diff = Main.currentScore;
            var score:Object = {'value':Main.currentScore};
            Main.currentScore = Main.currentScore - diff;
            new GTween(score, .3, {'value':score.value-diff}, {'ease':Linear.easeNone, 'onChange':function(t:GTween):void {
                (parent as Interstitial).repairText.text = "Gold: " + Hud.commafy(int(Math.round(score.value)));
                Hud.instance.score.text = Hud.commafy(int(Math.round(score.value)));
            }, 'onComplete':function():void {
                SoundBoard.playEffect("reachEnd");
                new GTween(self, .3, {'x':_start_point.x, 'y':_start_point.y}, {'ease':Linear.easeNone});
            }});
            _ship.health = _ship.health + heal;
            var ship_sprite:BitmapData = new BitmapData(_ship_bmp.width, _ship_bmp.height, true, 0);
            var bmpd:BitmapData = (_ship.graphic as Spritemap).source;
            ship_sprite.copyPixels(bmpd, ship_sprite.rect, ship_sprite.rect.topLeft);
            _ship_bmp.bitmapData = ship_sprite;
            var life_pct:Number = _ship.health / Ship.TOTAL_HEALTH;
            _life_bar.fillRect(new Rectangle(0, 0, Math.round(life_pct * (_life_bar.width)), 2), 0x00ff00);
        }
    }
    
    private function init(evt:Event):void {
        removeEventListener(Event.ADDED_TO_STAGE, init);
        if (_ship) {
            var life_pct:Number = _ship.health / FP.getClass(_ship).TOTAL_HEALTH;
            _start_point = new Point(x, y);
            _life_bar.fillRect(new Rectangle(0, 0, Math.round(life_pct * (_life_bar.width)), 2), (life_pct <= .5) ? 0xff0000 : 0x00ff00);
            var bmp:Bitmap = new Bitmap(_life_bar);
            bmp.x = (_ship is Airship) ? 7 : 2, bmp.y = (_ship is Airship) ? -4 : -2;
            addChild(bmp);
        }
        addChild(_ship_bmp);
    }
}