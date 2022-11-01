#if defined _pro_xp_natives_included
    #endinput
#endif
#define _pro_xp_natives_included


public int Native_GetPlayerLevel(Handle plugin, int numParams) {
    int client = GetNativeCell(1);
    return levels[client];
}

public int Native_GetPlayerXP(Handle plugin, int numParams) {
    int client = GetNativeCell(1);
    return player_xp[client];
}

public int Native_LevelToXP(Handle plugin, int numParams) {
    int lvl = GetNativeCell(1);
    return exp_points(lvl);
}

public int Native_XPToLevel(Handle plugin, int numParams) {
    int xp = GetNativeCell(1);
    return level(xp);
}

public int Native_NextLevel(Handle plugin, int numParams) {
    int client = GetNativeCell(1);
    return next_levels[client];
}

public int Native_GetMaxLevel(Handle plugin, int numParams) {
    return LEVEL_CAP;
}

public int Native_SetXPMultiplier(Handle plugin, int numParams) {
    float multiplier = GetNativeCell(1);
    xp_multiplier = multiplier;
    #if DEBUGGING
        LogToFile(logfile, "Set xp multiplier to %f", multiplier);
    #endif
}

public any Native_GetXPMultiplier(Handle plugin, int numParams) {
    return xp_multiplier;
}


void Forward_OnPlayerLevelUp(int client, int oldLevel, int newLevel) {
    if(oldLevel == LEVEL_CAP || newLevel <= oldLevel) {
        return;
    }
    
    SetLevelTag(client);
    SetStamina(client);
    
    if(newLevel % HIGHLIGHT_INTERVAL == 0) {
        #if SOUNDS_ENABLED == true
            EmitSoundToAll(sound_level_up_high);
        #endif
        CPrintToChatAllEx(client, "Player {teamcolor}%N{default} reached level {red}%i", client, newLevel)
    } else if(newLevel < LEVEL_CAP) {
        #if SOUNDS_ENABLED == true
            EmitSoundToAll(sound_level_up);
        #endif
        CPrintToChatAllEx(client, "Player {teamcolor}%N{default} leveled up to level %i", client, newLevel)
    } else {
        #if SOUNDS_ENABLED == true
            EmitSoundToAll(sound_level_up_high);
        #endif
        CPrintToChatAllEx(client, "Player {teamcolor}%N{default} reached the maxiumum level of {red}%i", client, LEVEL_CAP);
    }
    
    CPrintToChat(client, "Type !level to see your current progress or !xphelp for more commands");
    levels[client] = newLevel;
    next_levels[client] = exp_points(newLevel+1);
    
    Call_StartForward(level_up_forward);
    Call_PushCell(client);
    Call_PushCell(oldLevel);
    Call_PushCell(newLevel);
    Call_Finish();
}

void Forward_OnGainXP(int client, int victim, int xp, int damage, bool killshot, bool headshot, bool noscope, bool jumpshot, bool grenade_hit) {
    if(!enabled) {
        return;
    }
    
    player_xp[client] += xp;
    player_stats[client].hit(xp, damage, false, headshot, noscope, jumpshot, (grenade_hit & killshot));
    Call_StartForward(gain_xp_forward);
    Call_PushCell(client);
    Call_PushCell(victim);
    Call_PushCell(xp);
    Call_PushCell(damage);
    Call_PushCell(killshot);
    Call_PushCell(headshot);
    Call_PushCell(noscope);
    Call_PushCell(jumpshot);
    Call_PushCell(grenade_hit);
    Call_Finish();
    CheckLevelUp(client);
}
