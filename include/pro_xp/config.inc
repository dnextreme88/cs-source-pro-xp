#if defined _pro_xp_config_included
    #endinput
#endif
#define _pro_xp_config_included


// Do not add a file extension; a date will be appended in the form of: YYYY-MM-DD.log
// #define XP_LOG_FILE "addons/sourcemod/logs/pro-xp"
#define XP_LOG_FILE "logs/pro-xp"

#define DEBUGGING false

// maximum level - users will continue to gain xp but the displayed level will not change
#define LEVEL_CAP 100

// == Logarithmic xp algorithm constants ==

 // Defines the steepness of the xp curve - higher values result in a smaller xp gap between levels
#define A 18.0

 // Defines the initial xp gap - smaller values result in a higher gap
#define B -195.0

 // Whenever A or B are changed set this to `Exponential((1 - B) / A)`
 // You can use the excel formula: `=EXP((1 - B1) / A1)` where A1 and B1 are the constants A and B respectively.
// #define C 53577.7360672744
#define C Exponential((1 - B) / A)

 // e (Euler's number)
#define E 2.7182818284590452353602874713527


// Calculate the level from the amount of xp
public int level(int exp) {
    // XP Formula: Max(Floor(A * Log(xp + C)+B), 1)
    //  note: Log here is the natural logarithm, so use log base e
    float xp = float(exp);
    int lvl = RoundToFloor(A * Logarithm(xp + C, E) + B);
    if(lvl == 0) {
        return 1;
    } else if (lvl > LEVEL_CAP) {
        return LEVEL_CAP;
    } else {
        return lvl;
    }
}

// Given a level find the minimum amount of xp needed for that level
public int exp_points(int level) {
    return RoundToFloor(Exponential((level - B) / A) - C);
}


// celebrate every Nth level-up
const int HIGHLIGHT_INTERVAL = 10; // prints a different message every N levels



// The amount of extra stamina a player receives is calculated by: `level / STAMINA_AWARD_INTERVAL`
// Set to 0.0 for no stamina award (only applied if ProSprint is running)
#define STAMINA_AWARD_INTERVAL 5.0



 // xp multiplier for a kill compared to just causing damage
#define KILL_MULT 1.1

// xp multiplier for headshots
#define HEADSHOT_MULT 1.3

// xp bonus for a noscope hit
#define NOSCOPE_BONUS 70

// xp bonus for a jumpshot hit
#define JUMPSHOT_BONUS 50

// xp bonus for hitting an airborne enemy
#define AIRBORNE_ENEMY_BONUS 35



// xp multipliers for bot difficulty
#define BOT_MULT_EASY 0.28
#define BOT_MULT_NORMAL 0.32
#define BOT_MULT_HARD 0.36
#define BOT_MULT_EXPERT 0.45

// XP multipliers for various weapons (does not need an entry for every weapon)
// These can be adjusted according to your preferences
stock void WeaponBonuses(StringMap map) {
    map.SetValue("scout", 2.0);
    map.SetValue("knife", 6.0);
    map.SetValue("p228", 2.0);
    map.SetValue("glock", 2.0);
    map.SetValue("usp", 1.8);
    map.SetValue("fiveseven", 1.3);
    map.SetValue("m3", 1.2);
    map.SetValue("hegrenade", 1.5);
    map.SetValue("smokegrenade", 0.0);
    map.SetValue("g3sg1", 0.4); // cuz autosniper
    map.SetValue("sg550", 0.4); // cuz autosniper
    map.SetValue("awp", 0.4); // awps do a lot of damage - so even it out
    map.SetValue("m4a1", 0.45); // otherwise disproportionate xp gains because of accuracy, rate of fire, and clip size
    map.SetValue("ak47", 0.9);
    map.SetValue("ump45", 1.2);
    map.SetValue("mp5navy", 1.2);
    map.SetValue("famas", 1.2);
    map.SetValue("galil", 1.2);
    map.SetValue("xm1014", 1.0);
    map.SetValue("tmp", 1.1);
    map.SetValue("mac10", 1.2);
    map.SetValue("m249", 0.4);
    map.SetValue("p90", 1.0);
}



// XP penalties for cheating - only works with little anticheat
//  amount of xp deducted when being banned for cheating
#define XP_PENALTY_BAN 100000

//  amount of xp deducted when cheats are detected
#define XP_PENALTY_DETECTION 0



// only display this many users in the rank
#define LIST_RANK_LIMIT 200

// how long to show the rank screen
#define RANK_MENU_TIME 30


// play sounds when someone levels-up
#define SOUNDS_ENABLED false

#if SOUNDS_ENABLED
// normal level-up sound - in the cstrike/sound folder
char sound_level_up[] = "cssp/success-low.mp3";
// level-up sound for every HIGHLIGHT_INTERVAL levels
char sound_level_up_high[] = "cssp/success-fanfare.mp3";
#endif



// Settings for users reaching the maximum level

// A value of false will use the LEVEL_CAP_TAG, true will add a prefix and suffix to the level.
#define LEVEL_CAP_PREFIX false
#define LEVEL_CAP_TAG "PRO"

// If LEVEL_CAP_PREFIX is true add the prefix and suffix to the level
#define LEVEL_CAP_TAG_PREFIX ""
#define LEVEL_CAP_TAG_SUFFIX ""

// Whether to execute a command when maxed player gets a knife kill
#define LEVEL_CAP_SOUND false

// When a player has reached the level cap and knives someone this command will
// be executed if LEVEL_CAP_SOUND is true.  Just a little something extra, if desired.
// An empty string will disable the command.
#define LEVEL_CAP_KNIFE_KILL_COMMAND ""

