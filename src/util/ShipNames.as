package util {
    public class ShipNames {
        private static const shipNames:Vector.<String> = Vector.<String>([
            "The Ambassador           ",
            "The Annihilated Merchant ",
            "The Torched Assault      ",
            "The Bane                 ",
            "The Blacksmith's Anvil   ",
            "The Bravery Blight       ",
            "The Challenger           ",
            "The Civilization         ",
            "The Courage Dragon       ",
            "The Exalted Impurity     ",
            "The Fighter              ",
            "The Foolish Wizard       ",
            "The Foul Crossbow        ",
            "The Ghost's Honor        ",
            "The God Falchion         ",
            "The Imperial Force       ",
            "The Journeyman's Armor   ",
            "The Lady Anastacia       ",
            "The Lady's Reputation    ",
            "The Lost Vigilance       ",
            "The Mad Ogre             ",
            "The Meditation Arch-angel",
            "The Mercy                ",
            "The Murderous Mace       ",
            "The Necromantic Elsie    ",
            "The Owl's Vestments      ",
            "The Paladin Market       ",
            "The Pedlar Sheri         ",
            "The Perfect Crime        ",
            "The Perfect Process      ",
            "The Philanthropist       ",
            "The Red Mine             ",
            "The Reliant Alvin        ",
            "The Shaman's Revolution  ",
            "The Shaman's Retribution ",
            "The True Discord         ",
            "Alicia's Fame            ",
            "Emad's Great Debate      ",
            "Moshen's Bartered Sushi  ",
            "Richard's Gamble         ",
            "The Dancing Florenzano   ",
            "Flight of the Ippolito   ",
            "The Great Shen           ",
            "Bryon's Curse            ",
            "The Aeon Sceptre         ",
            "The Angel Roberto        ",
            "The Bald Rapier          ",
            "The Boasting Orca        ",
            "The Brotherhood of Flux  ",
            "The Brutal Merchant      ",
            "The Cunning              ",
            "The Cursed Pretender     ",
            "The Enchanted Wizard     ",
            "The Fallen Elsie         ",
            "The God Rift             ",
            "The Great Hunter         ",
            "The Guardian             ",
            "The Haste Fang           ",
            "The Healer               ",
            "The Keen Falchion        ",
            "The Lady Killer          ",
            "Wrath of the Tai Tai     ",
            "The Marvelous Martin     ",
            "The Murderer's Nebula    ",
            "The Romantic Stalker     ",
            "The Rushing Medallion    ",
            "The Serpent's Life       ",
            "The Spirit Trader        ",
            "The Spiritual Bard       ",
            "The Uncivilized Glory    ",
            "The Vigilant Assassin    ",
            "The Wandering Goddess    ",
            "The Wealthy Dog          "
        ]);
        private static var _in_use:Vector.<Boolean>;
        {
            _in_use = new Vector.<Boolean>(shipNames.length, true);
        }
        
        public function ShipNames():void {}
        
        public static function getShipName():String {
            var idx:int = -1;
            while (true) {
                idx = Main.random(shipNames.length-1);
                if (!_in_use[idx]) {
                    break;
                }
            }
            _in_use[idx] = true;
            return shipNames[idx];
        }
    }
}