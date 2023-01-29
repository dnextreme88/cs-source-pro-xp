#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdktools_hooks>
#include <morecolors.inc>

#include <pro_xp/config.inc>
#include <pro_xp/ProXP.inc>
#include <pro_xp/vars.inc>
#include <pro_xp/natives.inc>
#include <pro_xp/commands.inc>

#undef REQUIRE_PLUGIN
#include <ProZoom.inc>
#include <ProSprint.inc>
#define REQUIRE_PLUGIN


public Plugin myinfo = {
    name = "Pro XP",
    author = "Vishus",
    description = "Stats and XP level system",
    version = "0.2.0",
    url = "https://github.com/vishusandy/ProXP"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {
    late_loaded = late;
    RegPluginLibrary("pro_xp");
    CreateNative("ProXP_GetPlayerLevel", Native_GetPlayerLevel);
    CreateNative("ProXP_GetPlayerXP", Native_GetPlayerXP);
    CreateNative("ProXP_LevelToXP", Native_LevelToXP);
    CreateNative("ProXP_XPToLevel", Native_XPToLevel);
    CreateNative("ProXP_NextLevel", Native_NextLevel);
    CreateNative("ProXP_GetMaxLevel", Native_GetMaxLevel);
    CreateNative("ProXP_GetXPMultiplier", Native_GetXPMultiplier);
    CreateNative("ProXP_SetXPMultiplier", Native_SetXPMultiplier);
    return APLRes_Success;
}

public void OnPluginStart() {
    SetLogFile();

    if (STAMINA_AWARD_INTERVAL == 0) {
        // avoids division by zero
        stamina_award = 0.0;
    } else {
        // store the reciprocal of STAMINA_AWARD_INTERVAL so we can use multiplication instead of division (slightly faster, and no reason not to)
        stamina_award = 1.0 / STAMINA_AWARD_INTERVAL;
    }

    Database.Connect(DbConnCallback, "pro_xp");

    weapon_multipliers = new StringMap();
    WeaponBonuses(weapon_multipliers);

    normal_weapons = new StringMap();
    for (int i = 0; i < sizeof(guns); i++) {
        normal_weapons.SetValue(guns[i], i);
    }

    cvar_bot_difficulty = FindConVar("bot_difficulty");
    bot_difficulty = GetConVarInt(cvar_bot_difficulty);
    if (bot_difficulty >= sizeof(bot_mult)) {
        bot_difficulty = sizeof(bot_mult)-1;
    }

    HookConVarChange(cvar_bot_difficulty, BotDifficultyChanged);

    dump_file = CreateConVar("sm_xp_dump_file", "logs/pro_xp_dump.txt");

    level_up_forward = new GlobalForward("OnPlayerLevelUp", ET_Ignore, Param_Cell, Param_Cell, Param_Cell);
    gain_xp_forward = new GlobalForward("OnGainXP", ET_Ignore, Param_Cell, Param_Cell, Param_Cell, Param_Cell, Param_Cell, Param_Cell, Param_Cell, Param_Cell, Param_Cell);

    HookEvent("round_start", EventRoundStart);
    HookEvent("player_hurt", EventPlayerHurt);
    HookEvent("weapon_fire", EventPlayerShoot);
    HookEvent("player_spawn", EventPlayerSpawn);
    HookEvent("player_death", EventPlayerDeath);
    HookEvent("player_disconnect", EventPlayerDisconnect);

    RegConsoleCmd("level", CommandLevel);
    RegConsoleCmd("ranking", ShowLevelRanking);
    RegConsoleCmd("top", ShowLevelRanking);
    RegConsoleCmd("rankings", ShowLevelRanking);
    RegConsoleCmd("myrank", ShowPersonalRank);
    RegConsoleCmd("sm_rank", ShowPersonalRank);
    RegConsoleCmd("xphelp", ShowLevelHelp);
    RegConsoleCmd("rankhelp", ShowLevelHelp);
    RegConsoleCmd("levelhelp", ShowLevelHelp);
    RegConsoleCmd("statistics", ShowStats);
    RegConsoleCmd("sm_stats", ShowStats);
    RegConsoleCmd("morestats", ShowMoreStats);
    RegConsoleCmd("stat", ShowStats);
    RegConsoleCmd("kd", ShowStats);
    RegConsoleCmd("session", ShowSession);
    RegConsoleCmd("overall", ShowOverallStats);
    // RegConsoleCmd("season", ShowSeasonLevelRanking);

    RegServerCmd("dumpxp", DumpXP);
    RegServerCmd("listxp", ListXP);

    #if SOUNDS_ENABLED == true
        CacheSounds();
    #endif
}

public void OnAllPluginsLoaded() {
    zoom_loaded = LibraryExists("pro_zoom");
    sprint_loaded = LibraryExists("pro_sprint");
}

public void OnLibraryRemoved(const char[] name) {
    if (StrEqual(name, "pro_zoom")) {
        zoom_loaded = false;
    } else if (StrEqual(name, "pro_sprint")) {
        sprint_loaded = false;
    }
}

public void OnLibraryAdded(const char[] name) {
    if (StrEqual(name, "pro_zoom")) {
        zoom_loaded = true;
    } else if (StrEqual(name, "pro_sprint")) {
        sprint_loaded = true;
    }
}

public Action lilac_cheater_detected(int client, int cheat) {
    #if XP_PENALTY_DETECTION
        DockXP(client, XP_PENALTY_DETECTION, true);
    #endif
    return Plugin_Continue;
}

public Action lilac_cheat_banned(int client, int cheat) {
    #if XP_PENALTY_BAN
        DockXP(client, XP_PENALTY_BAN, true);
    #endif
    return Plugin_Continue;
}

void DockXP(int client, int xp_penalty, bool ban) {
    char steam_buff[STEAM_ID_LEN];
    char query[256];
    char penalty[24];
    int xp = player_xp[client];
    player_xp[client] = (xp > xp_penalty)? xp - xp_penalty: 0;

    // ADDED
    char name_buff1[MAX_NAME_LENGTH];
    char client_name1[MAX_NAME_LENGTH*3+10];
    GetClientName(client, name_buff1, sizeof(name_buff1));
    DB.Escape(name_buff1, client_name1, sizeof(client_name1));

    if (GetClientAuthId(client, AuthId_Steam3, steam_buff, STEAM_ID_LEN)) {
        Format(query, sizeof(query), "UPDATE pro_xp SET xp = GREATEST(xp-%i, 0) WHERE steamid = '%s' AND name = '%s'", xp_penalty, steam_buff, client_name1);
        SQL_LockDatabase(DB);
        SQL_FastQuery(DB, query);
        SQL_UnlockDatabase(DB);
    }

    if (xp_penalty > 0) {
        NumberFormat(xp_penalty, penalty, sizeof(penalty));
        CPrintToChat(client, "{red}You have been docked {green}%s xp{default} for cheating.", penalty);
    }

    if (ban) {
        CPrintToChat(client, "{red}Disable your cheats{default} and you can come back in {red}5 minutes.");
    }
}


public void DbConnCallback(Database db, const char[] error, any data) {
    if (strlen(error) > 0) {
        LogToFile(logfile, "Could not connect to xp database: %s", error);
        return;
    }

    DB = db;
    Setup();
}

public void OnPluginEnd() {
    SetLogFile();
    UpdateAllXP();

    delete weapon_multipliers;
    delete DB;
    delete normal_weapons;
}

#if SOUNDS_ENABLED == true
    void CacheSounds() {
        char buffer[256];

        PrecacheSound(sound_level_up, true);
        Format(buffer, sizeof(buffer), "sound/%s", sound_level_up);
        AddFileToDownloadsTable(buffer);

        PrecacheSound(sound_level_up_high, true);
        Format(buffer, sizeof(buffer), "sound/%s", sound_level_up_high);
        AddFileToDownloadsTable(buffer);
    }
#endif

public void Setup() {
    char db_ident[16];

    // Find out which database driver is being used
    SQL_ReadDriver(DB, db_ident, sizeof(db_ident));

    SQL_LockDatabase(DB); // this is already running in a thread (from Database.Connect()) so it should be fine to use blocking queries here as long as the other queries are async

    // Auto create the table based on which driver is being used
    if (StrEqual(db_ident, "mysql", false)) {
        SQL_FastQuery(DB, "CREATE TABLE IF NOT EXISTS `pro_xp` (`id` int(11) NOT NULL, `steamid` varchar(32) DEFAULT NULL, `name` varchar(64) DEFAULT NULL, `xp` int(11) NOT NULL DEFAULT '0', `sxp` int(11) DEFAULT '0', `steam3` varchar(32) DEFAULT NULL, `deaths` int(11) NOT NULL DEFAULT '0', `kills` int(11) NOT NULL DEFAULT '0', `hits` int(11) NOT NULL DEFAULT '0', `shots` int(11) NOT NULL DEFAULT '0', `jumpshots` int(11) NOT NULL DEFAULT '0', `noscopes` int(11) NOT NULL DEFAULT '0', `knife_kills` int(11) NOT NULL DEFAULT '0', `headshots` int(11) NOT NULL DEFAULT '0', `damage` bigint(11) NOT NULL DEFAULT '0', `grenade_kills` int(11) NOT NULL DEFAULT '0', `first_bloods` int(11) NULL DEFAULT '0', `games_count` int(11) NULL DEFAULT '0') ENGINE=InnoDB DEFAULT CHARSET=latin1;");
        SQL_FastQuery(DB, "ALTER TABLE `pro_xp` ADD PRIMARY KEY (`id`);");
        SQL_FastQuery(DB, "ALTER TABLE `pro_xp` MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;");
    } else if (StrEqual(db_ident, "sqlite")) {
        SQL_FastQuery(DB, "CREATE TABLE IF NOT EXISTS 'pro_xp' ('id' INTEGER NOT NULL, 'steamid' TEXT NOT NULL, 'name' TEXT NOT NULL, 'xp' INTEGER NOT NULL DEFAULT 0, 'sxp' INTEGER NOT NULL DEFAULT 0, 'steam3' TEXT NOT NULL UNIQUE, 'deaths' INTEGER NOT NULL DEFAULT 0, 'kills' INTEGER NOT NULL DEFAULT 0, 'hits' INTEGER NOT NULL DEFAULT 0, 'shots' INTEGER NOT NULL DEFAULT 0, 'jumpshots' INTEGER NOT NULL DEFAULT 0, 'noscopes' INTEGER NOT NULL DEFAULT 0, 'knife_kills' INTEGER NOT NULL DEFAULT 0, 'headshots' INTEGER NOT NULL DEFAULT 0, 'damage' INTEGER NOT NULL DEFAULT 0, 'grenade_kills' INTEGER NOT NULL DEFAULT 0, 'first_bloods' INTEGER NULL DEFAULT 0, 'games_count' INTEGER NULL DEFAULT 0 PRIMARY KEY('id' AUTOINCREMENT));");
    } else if (StrEqual(db_ident, "pgsql")) {
        SQL_FastQuery(DB, "CREATE TABLE IF NOT EXISTS 'pro_xp' (id integer NOT NULL, steamid character varying(32) NOT NULL, name character varying(128) NOT NULL, xp integer DEFAULT 0 NOT NULL, sxp integer DEFAULT 0 NOT NULL, steam3 character varying(32) NOT NULL, deaths integer DEFAULT 0 NOT NULL, kills integer DEFAULT 0 NOT NULL, hits integer DEFAULT 0 NOT NULL, shots integer DEFAULT 0 NOT NULL, jumpshots integer DEFAULT 0 NOT NULL, noscopes integer DEFAULT 0 NOT NULL, knife_kills integer DEFAULT 0 NOT NULL, headshots integer DEFAULT 0 NOT NULL, damage integer DEFAULT 0 NOT NULL, grenade_kills integer DEFAULT 0 NOT NULL, first_bloods integer DEFAULT 0 NULL, games_count integer DEFAULT 0 NULL);");
        SQL_FastQuery(DB, "CREATE SEQUENCE IF NOT EXISTS pro_xp_id_seq START WITH 1  INCREMENT BY 1  NO MINVALUE  NO MAXVALUE  CACHE 1;");
        SQL_FastQuery(DB, "ALTER TABLE ONLY pro_xp ALTER COLUMN id SET DEFAULT nextval('pro_xp_id_seq'::regclass);");
        SQL_FastQuery(DB, "ALTER TABLE ONLY pro_xp ADD CONSTRAINT pro_xp_pkey PRIMARY KEY (id);");
        SQL_FastQuery(DB, "ALTER TABLE ONLY pro_xp ADD CONSTRAINT pro_xp_steam3_key UNIQUE (steam3);");
    } else {
        ThrowError("Invalid database driver specified: creating tables automatically for '%s' is not supported.  Please create the table manually.", db_ident);
    }
    SQL_UnlockDatabase(DB);

    enabled = true;
    if (late_loaded) {
        for (int i = 1; i <= MaxClients; i++) {
            if (IsClientInGame(i)) {
                PlayerJoinSetup(i);
            }
        }
    }

    late_loaded = false;
}

public void OnClientAuthorized(int client, const char[] auth) {
    if (!enabled) {
        return;
    }

    PlayerJoinSetup(client);
}

public EventRoundStart(Handle:event, const String:name[], bool:dontBroadcast) {
    totalKills = 0; // Reset total kills so we can properly identify the first blood on the player_death event
    strcopy(firstBloodAttacker, sizeof(firstBloodAttacker), "");
    strcopy(firstBloodVictim, sizeof(firstBloodVictim), "");
}

public Action EventPlayerDisconnect(Handle event, const char[] name, bool dontBroadcast) {
    int client = GetClientOfUserId(GetEventInt(event, "userid"));
    if (!enabled || client == 0) {
        return Plugin_Continue;
    }

    UpdateDatabaseXP(client);

    return Plugin_Continue;
}

public Action EventPlayerDeath(Handle event, const char[] name, bool dontBroadcast) {
    int victim = GetClientOfUserId(GetEventInt(event, "userid"));
    int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));

    if (attacker > 0) {
        player_stats[attacker].kill();
    }

    if (!enabled || victim == 0) {
        return Plugin_Continue;
    }

    player_stats[victim].death();
    UpdateDatabaseXP(victim);

    if (victim == 0) {
        return Plugin_Continue;
    } else {
        char attackerName[64];
        GetClientName(attacker, attackerName, sizeof(attackerName));

        char victimName[64];
        GetClientName(victim, victimName, sizeof(victimName));

        if (GetClientTeam(attacker) != GetClientTeam(victim)) { // Attacker and victim are not on the same team
            totalKills += 1;

            if (totalKills == 1) { // First kill on opposing team
                strcopy(firstBloodAttacker, sizeof(firstBloodAttacker), attackerName);
                strcopy(firstBloodVictim, sizeof(firstBloodVictim), victimName);

                CPrintToChatEx(attacker, victim, "{cyan}[ProXP] {default}Congrats! You dealt first blood to {teamcolor}%s{default}!", victimName);
                CPrintToChatEx(victim, attacker, "{cyan}[ProXP] {default}You were killed first in this round by {teamcolor}%s{default}!", attackerName);

                player_stats[attacker].first_blood();
                UpdateDatabaseXP(attacker);
            }
        }
    }
    return Plugin_Continue;
}

public Action EventPlayerShoot(Handle event, const char[] name, bool dontBroadcast) {
    int client = GetClientOfUserId(GetEventInt(event, "userid"));

    if (!enabled || client == 0) {
        return Plugin_Continue;
    }

    player_stats[client].shoot();

    return Plugin_Continue;
}

public Action EventPlayerSpawn(Handle event, const char[] name, bool dontBroadcast) {
    int client = GetClientOfUserId(GetEventInt(event, "userid"));

    if (!enabled) {
        return Plugin_Continue;
    }

    if (!CheckLevelUp(client)) {
        SetStamina(client, false);
        SetLevelTag(client);
    }
    return Plugin_Continue;
}


public void OnMapStart() {
    if (!enabled) {
        return;
    }

    #if SOUNDS_ENABLED == true
        CacheSounds();
    #endif

    SetLogFile();
}

public Action EventPlayerHurt(Handle event, const char[] name, bool dontBroadcast) {
    if (!enabled) {
        return Plugin_Continue;
    }

    int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
    int victim = GetClientOfUserId(GetEventInt(event, "userid"));

    if (victim == 0 || attacker == 0 || attacker == victim || levels[attacker] == 0) {
        return Plugin_Continue;
    }

    int damage = 0;
    bool killshot, headshot, noscope, jumpshot, grenade, isFirstBlood = false;
    int xp = CalculateXP(event, damage, killshot, headshot, noscope, jumpshot, grenade, isFirstBlood);
    Forward_OnGainXP(attacker, victim, xp, damage, killshot, headshot, noscope, jumpshot, grenade, isFirstBlood);
    return Plugin_Continue;
}


public void PlayerJoinSetup(int client) {
    if (!enabled || client == 0) {
        LogToFile(logfile, "PlayerJoinSetup exiting - client %i not valid", client);
        return;
    }

    if (!GetClientAuthId(client, AuthId_Steam3, steam_ids[client], STEAM_ID_LEN)) {
        LogToFile(logfile, "Failed to get SteamID for %N (client %i)", client, client);
        // return;
    }

    char query[300];

    // ADDED
    char name_buff2[MAX_NAME_LENGTH];
    char client_name2[MAX_NAME_LENGTH*3+10];
    GetClientName(client, name_buff2, sizeof(name_buff2));
    DB.Escape(name_buff2, client_name2, sizeof(client_name2));

    Format(query, sizeof(query), "SELECT xp, deaths, kills, hits, shots, jumpshots, noscopes, knife_kills, headshots, damage, grenade_kills, first_bloods, games_count FROM pro_xp WHERE steamid = '%s' AND name = '%s'", steam_ids[client], client_name2);
    DB.Query(PlayerJoinGetXPCallback, query, client);
}


public void PlayerJoinGetXPCallback(Database db, DBResultSet result, const char[] error, int client) {
    if (!enabled || client == 0) {
        return;
    }

    if (strlen(error) > 0) {
        LogToFile(logfile, "Join callback error: %s", error);
    }

    if (result != null && result.FetchRow()) {
        int exp = result.FetchInt(0);
        SetClientXP(client, exp);

        int deaths = result.FetchInt(1);
        int kills = result.FetchInt(2);
        int hits = result.FetchInt(3);
        int shots = result.FetchInt(4);
        int jumpshots = result.FetchInt(5);
        int noscopes = result.FetchInt(6);
        int knife_kills = result.FetchInt(7);
        int headshots = result.FetchInt(8);
        int damage = result.FetchInt(9);
        int grenade_kills = result.FetchInt(10);
        int first_bloods = result.FetchInt(11);
        int games_count = result.FetchInt(12);
        int inc_games_count = games_count + 1;

        #if DEBUGGING
            LogToFile(logfile, "%N joined with %i xp", client, exp);
        #endif
        player_stats[client].join(exp, deaths, kills, hits, shots, jumpshots, noscopes, knife_kills, headshots, damage, grenade_kills, first_bloods);

        // Update games_count field
        char query_update[256];
        char name_buff[MAX_NAME_LENGTH];
        char client_name[MAX_NAME_LENGTH*3+10];
        GetClientName(client, name_buff, sizeof(name_buff));
        db.Escape(name_buff, client_name, sizeof(client_name));

        Format(query_update, sizeof(query_update), "UPDATE pro_xp SET games_count = %i WHERE name = '%s'", inc_games_count, client_name);
        SQL_LockDatabase(db);
        SQL_FastQuery(db, query_update);
        SQL_UnlockDatabase(db);
        // End update

        InstantSetStamina(client);
        SetLevelTag(client);
    } else {
        player_stats[client].reset();
        char name_buff[MAX_NAME_LENGTH];
        char client_name[MAX_NAME_LENGTH*3+10];
        char temp_Steam64[STEAM_ID_LEN];
        GetClientName(client, name_buff, sizeof(name_buff));
        DB.Escape(name_buff, client_name, sizeof(client_name));
        #if DEBUGGING
            LogToFile(logfile, "0.Creating xp record for new player: %N (client=%i)", client, client);
        #endif
        GetClientAuthId(client, AuthId_SteamID64, temp_Steam64, STEAM_ID_LEN);

        char query[MAX_NAME_LENGTH*3+10+128];

        Format(query, sizeof(query), "INSERT INTO pro_xp (steamid, name, xp, sxp, steam3, games_count) VALUES('%s', '%s', 0, 0, '%s', 1)", steam_ids[client], client_name, temp_Steam64);
        DB.Query(PlayerJoinInsertXPCallback, query);

        PrintToServer("Creating new client %s in table", client_name);

        SetClientXP(client, 0);
    }
}

public void PlayerJoinInsertXPCallback(Database db, DBResultSet result, const char[] error, int client) {
    if (strlen(error) > 0) {
        LogToFile(logfile, "insert xp error: %s", error);
    }

    if (result.AffectedRows == 0) {
        LogToFile(logfile, "xp record insert returned with 0 affected rows");
    }
}


public void UpdateDatabaseXP(int client) {
    if (!enabled || player_xp[client] <= 0) {
        return;
    }

    #if DEBUGGING
        LogToFile(logfile, "Updating xp for %N to: stat_xp=%i player_xp=%i", client, player_stats[client].start.xp + player_stats[client].session.xp, player_xp[client]);
    #endif

    // ADDED
    char name_buff4[MAX_NAME_LENGTH];
    char client_name4[MAX_NAME_LENGTH*3+10];
    GetClientName(client, name_buff4, sizeof(name_buff4));
    DB.Escape(name_buff4, client_name4, sizeof(client_name4));

    // UPDATE query under include/pro_xp/vars.inc
    player_stats[client].update(DB, steam_ids[client], client_name4);
}

public void UpdateDatabaseXPCallback(Database db, DBResultSet result, const char[] error, int client) {
    if (strlen(error) > 0) {
        LogToFile(logfile, "Error updating xp: %s", error);
    } else if (result.AffectedRows == 0) {
        char query[128];

        // ADDED
        char name_buff5[MAX_NAME_LENGTH];
        char client_name5[MAX_NAME_LENGTH*3+10];
        GetClientName(client, name_buff5, sizeof(name_buff5));
        DB.Escape(name_buff5, client_name5, sizeof(client_name5));

        Format(query, sizeof(query), "SELECT xp FROM pro_xp WHERE steamid = '%s' AND name = '%s'", steam_ids[client], client_name5);
        DB.Query(UpdateXPFailCheckQuery, query, client);
    }
}

public void UpdateXPFailCheckQuery(Database db, DBResultSet result, const char[] error, int client) {
    if (strlen(error) > 0) {
        LogToFile(logfile, "Error in update XP: %s", error);
    } else if (result != null && result.FetchRow()) {
        int exp = result.FetchInt(0);
        if (player_xp[client] > exp) {
            // this may be inaccurately triggered by the player gaining xp between when the asyncronous db call is made and when it returns
            LogToFile(logfile, "ERROR: failed to update XP for client %i from %i to %i", client, player_xp[client], exp);
        } else if (player_xp[client] < exp) {
            // There was a discrepancy between the xp in memory and in the database; the database xp was lager which should have otherwise subtracted from the player's xp
            LogToFile(logfile, "ERROR: Update failed - attempted to update client %i (steamid=%s) xp from a lesser amount of %i to %i", client, steam_ids[client], player_xp[client], exp);
        }
    }
}

public void SetClientXP(int client, int xp) {
        player_xp[client] = xp;
        int lvl = level(xp);
        levels[client] = lvl;
        next_levels[client] = exp_points(lvl+1);
}

// Takes an event and some references to variables in order to return more information about how the xp was calculated
// Currently does not return information on whether a weapon bonus was given or an airborne enemy bonus
public int CalculateXP(Handle event, int &damage, bool &killshot, bool &headshot, bool &noscope, bool &jumpshot, bool &grenade, bool &isFirstBlood) {
    int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
    int victim = GetClientOfUserId(GetEventInt(event, "userid"));
    int hp = GetEventInt(event, "health");
    damage = GetEventInt(event, "dmg_health");
    int hitgroup = GetEventInt(event, "hitgroup");
    char weapon[48];
    GetEventString(event, "weapon", weapon, sizeof(weapon));
    float bonus_mult = 1.0;
    int bonus_add = 0;
    int weapon_index;

    // This must evaluated first as it overwrites the value of bonus_mult
    weapon_multipliers.GetValue(weapon, bonus_mult);
    bool is_gun = normal_weapons.GetValue(weapon, weapon_index);

    grenade = (StrEqual(weapon, "hegrenade"))? true: false;
    // for poison smoke
    bool not_smoke = (StrEqual(weapon, "smokegrenade"))? false: true;
    bool is_knife = (StrEqual(weapon, "knife"))? true: false;

    if (not_smoke && hp <= 0) {
        bonus_mult *= KILL_MULT;
        killshot = true;
    } else {
        killshot = false;
    }

    if (hp <= 0 && is_knife) {
        player_stats[attacker].knife_kill();
    }

    if (is_gun && hitgroup == HITGROUP_HEAD) {
        bonus_mult *= HEADSHOT_MULT;
        headshot = true;
    } else {
        headshot = false;
    }

    if (zoom_loaded) {
        int zoom_level = ProZoom_GetZoomLevel(attacker);
        if (ProZoom_IsSniperRifle(weapon) && zoom_level == 0) {
            bonus_add += NOSCOPE_BONUS;
            noscope = true;
        } else {
            noscope = false;
        }
    } else {
        noscope = false;
    }

    // Consider it a jumpshot if: attacker has a gun that's in the `guns` array (grenades etc don't count) and isn't on the ground
    if ((is_gun | is_knife) && !(GetEntityFlags(attacker) & FL_ONGROUND)) {
        bonus_add += JUMPSHOT_BONUS;
        jumpshot = true;
    } else {
        jumpshot = false;
    }

    // If the enemy is airborne add a smaller bonus but don't mark as a jumpshot
    if (not_smoke && !(GetEntityFlags(victim) & FL_ONGROUND)) {
        bonus_add += AIRBORNE_ENEMY_BONUS;
    }

    if (isFirstBlood) {
        bonus_add += FIRST_BLOOD_BONUS
    }

    if (IsFakeClient(victim)) {
        bonus_mult *= bot_mult[bot_difficulty];
    }
    bonus_mult *= xp_multiplier;

    #if SOUNDS_ENABLED && LEVEL_CAP_SOUND
        if (strlen(LEVEL_CAP_KNIFE_KILL_COMMAND) != 0 && is_knife && killshot && attacker > 0 && levels[attacker] >= LEVEL_CAP) {
            FakeClientCommandEx(attacker, LEVEL_CAP_KNIFE_KILL_COMMAND);
        }
    #endif

    int amount = RoundToFloor(float(damage) * bonus_mult) + bonus_add;

    return amount;
}

public bool CheckLevelUp(int client) {
    if (player_xp[client] > next_levels[client]) {
        Forward_OnPlayerLevelUp(client, levels[client], levels[client]+1);
        return true;
    }

    return false;
}

public void SetLevelTag(int client) {
    if (!IsClientInGame(client) || levels[client] == 0) {
        return;
    }

    char buff[24];

    if (levels[client] >= LEVEL_CAP) {
        #if LEVEL_CAP_PREFIX
            Format(buff, sizeof(buff), "%s[Lv. %i]%s", LEVEL_CAP_TAG_PREFIX, levels[client], LEVEL_CAP_TAG_SUFFIX);
        #else
            Format(buff, sizeof(buff), "%s", LEVEL_CAP_TAG);
        #endif
        CS_SetMVPCount(client, LEVEL_CAP);
    } else {
        Format(buff, sizeof(buff), "[Lv. %i]", levels[client]);
    }

    CS_SetClientClanTag(client, buff);
}

public Action DelayedSetLevelTag(Handle timer, int client) {
    SetLevelTag(client);
    return Plugin_Continue;
}

public void BotDifficultyChanged(ConVar convar, const char[] oldValue, const char[] newValue) {
    if (!enabled) {
        return;
    }

    int temp = StringToInt(newValue);
    if (temp >= sizeof(bot_mult)) {
        bot_difficulty = sizeof(bot_mult) - 1;
    } else {
        bot_difficulty = temp;
    }
}

// Helpers
// Source: https://forums.alliedmods.net/showthread.php?t=191743
AddComma( String: sString[ ], iSize, iPosition ) {
    new String: sTemp[ 32 ];
    FormatEx( sTemp, iPosition + 1, "%s", sString ), Format( sTemp, 31, "%s,", sTemp ), Format( sTemp, 31, "%s%s", sTemp, sString[ iPosition ] ), FormatEx( sString, iSize, "%s", sTemp );
}
NumberFormat( iNumber, String: sNumber[ ], iSize ) {
    new bool: bNegative = iNumber < 0 ? true : false;
    if ( bNegative ) iNumber *= -1;
    FormatEx( sNumber, iSize, "%d", iNumber );
    for ( new i = strlen( sNumber ) - 3; i > 0; i -= 3 ) AddComma( sNumber, iSize, i );
    if ( bNegative ) Format( sNumber, iSize, "-%s", sNumber );
}

float CalculateStamina(int lvl) {
    return float(RoundToFloor(float(lvl) * stamina_award)) + DEFAULT_STAMINA;
}

void SetStamina(int client, bool output=true) {
    if (!sprint_loaded) { return; }

    float stamina = CalculateStamina(levels[client]);
    ProSprint_SetPlayerStamina(client, stamina, -1.0);

    if (output && IsClientInGame(client)) {
        int extra = RoundToFloor(stamina - DEFAULT_STAMINA);
        CPrintToChat(client, "{red}+%i{default} stamina for being level {green}%i", extra, levels[client]);
    }
}

void InstantSetStamina(int client, bool output=true) {
    if (!sprint_loaded) { return; }

    if (output && IsClientInGame(client)) {
        float stamina = CalculateStamina(levels[client]);
        ProSprint_SetPlayerStamina(client, stamina, -1.0);
        int extra = RoundToFloor(stamina - DEFAULT_STAMINA);
        CPrintToChat(client, "{red}+%i{default} stamina for being level {green}%i", extra, levels[client]);
    } else if (output) {
        CreateTimer(5.0, DelayedSetStamina, client);
    } else {
        float stamina = CalculateStamina(levels[client]);
        ProSprint_SetPlayerStamina(client, stamina, -1.0);

    }
}

public Action DelayedSetStamina(Handle timer, int client) {
    SetStamina(client);
    return Plugin_Continue;
}

void UpdateAllXP() {
    if (!enabled) {
        return;
    }

    for (int i = 1; i <= MaxClients; i++) {
        if (IsClientInGame(i)) {
            UpdateDatabaseXP(i);
        }
    }
}

public void SetLogFile() {
    char date[sizeof(log_file_date)];
    FormatTime(date, sizeof(date), "%Y-%m-%d");

    char file_buffer[PLATFORM_MAX_PATH];
    FormatEx(logfile, sizeof(logfile), "%s_%s.log", XP_LOG_FILE, date);
    BuildPath(Path_SM, file_buffer, PLATFORM_MAX_PATH, logfile);
    logfile = file_buffer;

    if (!StrEqual(date, log_file_date)) {
        strcopy(log_file_date, sizeof(log_file_date), date);
        #if DEBUGGING
            LogToFile(logfile, "XP log file: %s", logfile);
        #endif
    }
}
