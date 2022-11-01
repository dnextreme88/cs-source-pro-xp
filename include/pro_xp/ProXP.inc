#if defined _pro_xp_included
    #endinput
#endif
#define _pro_xp_included

#include <morecolors.inc>

public SharedPlugin __pl_pro_xp = 
{
    name = "pro_xp",
    file = "ProXP.smx",
#if defined REQUIRE_PLUGIN
    required = 1,
#else
    required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_pro_xp_SetNTVOptional()
{
    MarkNativeAsOptional("ProXP_GetPlayerLevel");
    MarkNativeAsOptional("ProXP_GetPlayerXP");
    MarkNativeAsOptional("ProXP_LevelToXP");
    MarkNativeAsOptional("ProXP_XPToLevel");
    MarkNativeAsOptional("ProXP_NextLevel");
    MarkNativeAsOptional("ProXP_GetMaxLevel");
}
#endif



/**
 * Get the level of the specified player
 * 
 * @param client    Client index
 * @return          Returns the level
 */
native int ProXP_GetPlayerLevel(int client);

/**
 * Get the player's xp
 * 
 * @param client    Client index
 * @return          Returns the xp
 */
native int ProXP_GetPlayerXP(int client);

/**
 * How many xp points is required for the specified level
 * 
 * @param level     The level
 * @return          Returns the amount of xp required for the specified level
 */
native int ProXP_LevelToXP(int level);

/**
 * Returns the level for a specified amount of xp
 * @param xp        The amount of xp
 * @return          Returns the level for the specified amount of xp
 */
native int ProXP_XPToLevel(int xp);

/**
 * Returns the amount of total xp the player needs to level up
 * 
 * @param client    The client index of the player
 * @return          Returns the amount of xp their next level requires
 */
native int ProXP_NextLevel(int client);

/**
 * Returns the level cap (maximum level)
 * 
 * @return          Returns the maximum level
 */
native int ProXP_GetMaxLevel();

/**
 * Set the global xp multiplier.  This will be applied to every xp calculation.
 * 
 * @param multiplier    Set the multiplier to this value
 */
native void ProXP_SetXPMultiplier(float multiplier);

/**
 * Get the global xp multiplier.  This is the value that is applied to every xp calculation.
 * 
 * @return      Returns the multiplier that is applied to all xp calculations globally
 */
native float ProXP_GetXPMultiplier();


/**
 * Executed whenever a player levels up
 * 
 * @param client       The client leveling up
 * @param oldLevel     Their old level
 * @param newLevel     Their new level
 * @return
 */
forward void OnPlayerLevelUp(int client, int oldLevel, int newLevel);

/**
 * Executed whenever a player gains xp
 * 
 * @param client    The client index
 * @param victim    The player hurt/killed
 * @param xp        The amount of xp gained for the hit
 * @param damage    The amount of actual damage done
 * @param killshot  Whether the hit killed the victim or not
 * @param headshot  Whether the hit was a headshot or not
 * @param noscope   Whether the player used a scope
 * @param jumpshot  Whether the player was airborne
 * @param grenade_hit   Whether the hit was from a grenade
 * @return
 */
forward void OnGainXP(int client, int victim, int xp, int damage, bool killshot, bool headshot, bool noscope, bool jumpshot, bool grenade_hit);

