#if defined _pro_xp_vars_included
    #endinput
#endif
#define _pro_xp_vars_included



float xp_multiplier = 1.0;
float stamina_award;
float bot_mult[] = {BOT_MULT_EASY, BOT_MULT_NORMAL, BOT_MULT_HARD, BOT_MULT_EXPERT}; // 0=easy, 1=normal, 2=hard, 3=expert
char guns[][] = {"usp", "glock", "deagle", "p228", "elite", "fiveseven", "m4a1", "ak47", "awp", "scout", "sg552", "galil", "famas", "sg550", "aug", "m249", "g3sg1", "ump45", "mp5navy", "m3", "xm1014", "tmp", "mac10", "p90"};
#define	HITGROUP_HEAD   1
bool enabled = false;
bool late_loaded;
int bot_difficulty = 0;
StringMap weapon_multipliers;
StringMap normal_weapons;
Database DB;
ConVar cvar_bot_difficulty;
ConVar dump_file;
GlobalForward level_up_forward;
GlobalForward gain_xp_forward;

#define STEAM_ID_LEN 32
char log_file_date[16];
char logfile[PLATFORM_MAX_PATH];
char steam_ids[MAXPLAYERS+1][STEAM_ID_LEN];
int player_xp[MAXPLAYERS+1];
int levels[MAXPLAYERS+1];
int next_levels[MAXPLAYERS+1];
bool zoom_loaded;
bool sprint_loaded;



enum struct Stats {
    int xp;
    int deaths;
    int kills;
    int shots;
    int hits;
    int knife_kills;
    int noscopes;
    int jumpshots;
    int headshots;
    int damage;
    int grenade_kills;
    
    void join(int xp, int deaths, int kills, int hits, int shots, int jumpshots, int noscopes, int knife_kills, int headshots, int damage, int grenade_kills) {
        this.xp = xp;
        this.deaths = deaths;
        this.kills = kills;
        this.hits = hits;
        this.shots = shots;
        this.jumpshots = jumpshots;
        this.noscopes = noscopes;
        this.knife_kills = knife_kills;
        this.headshots = headshots;
        this.damage = damage;
        this.grenade_kills = grenade_kills;
    }
    void update(int xp, int damage, bool killshot, bool headshot, bool noscope, bool jumpshot, bool grenade_kill) {
        this.xp += xp;
        this.hits += 1;
        this.damage += damage;
        if(killshot)
            this.kills += 1;
        if(noscope)
            this.noscopes += 1;
        if(jumpshot)
            this.jumpshots += 1;
        if(headshot)
            this.headshots += 1;
        if(grenade_kill)
            this.grenade_kills += 1;
    }
    void reset() {
        this.xp = 0;
        this.deaths = 0;
        this.kills = 0;
        this.hits = 0;
        this.shots = 0;
        this.noscopes = 0;
        this.jumpshots = 0;
        this.knife_kills = 0;
        this.headshots = 0;
        this.damage = 0;
        this.grenade_kills = 0;
    }
    float kd() {
        int deaths = (this.deaths != 0)? this.deaths: 1;
        return float(this.kills)/float(deaths);
    }
    float accuracy() {
        return float(this.hits)/float(this.shots);
    }
    float overall_kd(int overall_kills, int overall_deaths) {
        int deaths0 = (this.deaths != 0)? this.deaths: 1;
        int deaths1 = (overall_deaths != 0)? overall_deaths: 1;
        return float(this.kills + overall_kills)/float(deaths0 + deaths1);
    }
    float overall_accuracy(int overall_hits, int overall_shots) {
        return float(this.hits + overall_hits)/float(this.shots + overall_shots);
    }
}

enum struct Players {
    Stats start;
    Stats session;
    void join(int xp, int deaths, int kills, int hits, int shots, int jumpshots, int noscopes, int knife_kills, int headshots, int damage, int grenade_kills) {
        this.start.join(xp, deaths, kills, hits, shots, jumpshots, noscopes, knife_kills, headshots, damage, grenade_kills);
        this.session.reset();
    }
    void hit(int xp, int damage, bool killshot, bool headshot, bool noscope, bool jumpshot, bool grenade_kill) {
        // note: killshot should always be false since Forward_OnGainXP always passes false (kills/deaths are updated in EventPlayerDeath)
        this.session.update(xp, damage, killshot, headshot, noscope, jumpshot, grenade_kill);
    }
    void shoot() {
        this.session.shots += 1;
    }
    void knife_kill() {
        this.session.knife_kills += 1;
    }
    void death() {
        this.session.deaths += 1;
    }
    void kill() {
        this.session.kills += 1;
    }
    void reset() {
        this.start.reset();
        this.session.reset();
    }
    void update(Database db, const char[] steamid) {
        char query[384];
        int xp = this.start.xp + this.session.xp;
        int deaths = this.start.deaths + this.session.deaths;
        int kills = this.start.kills + this.session.kills;
        int shots = this.start.shots + this.session.shots;
        int hits = this.start.hits + this.session.hits;
        int knife_kills = this.start.knife_kills + this.session.knife_kills;
        int noscopes = this.start.noscopes + this.session.noscopes;
        int jumpshots = this.start.jumpshots + this.session.jumpshots;
        int headshots = this.start.headshots + this.session.headshots;
        int damage = this.start.damage + this.session.damage;
        int grenade_kills = this.start.grenade_kills + this.session.grenade_kills;
        Format(query, sizeof(query), "UPDATE pro_xp SET xp=%i, deaths=%i, kills=%i, hits=%i, shots=%i, jumpshots=%i, noscopes=%i, knife_kills=%i, headshots=%i, damage=%i, grenade_kills=%i WHERE steamid = '%s' AND xp <= %i", xp, deaths, kills, hits, shots, jumpshots, noscopes, knife_kills, headshots, damage, grenade_kills, steamid, xp);
        
        #if DEBUGGING
            LogToFile(logfile, "Updating XP for steamid=%s to %i", steamid, xp);
        #endif
        
        db.Query(UpdateStatsCallback, query);
        // LogToFile(XP_LOG_FILE, "Updating stats: %s", query);
    }
    
    void stats(int client, bool kill_types=false, bool verbose=false) {
        this.session_stats(client, kill_types, verbose);
        this.overall_stats(client, kill_types, verbose);
    }
    
    void session_stats(int client, bool kill_types=false, bool verbose=false) {
        CPrintToChat(client, "{white}Session Stats:{default}");
        if(verbose) {
            CPrintToChat(client, "    Kills=%i Deaths=%i Damage=%i XP=%i", this.session.kills, this.session.deaths, this.session.damage, this.session.xp);
        }
        if(kill_types) {
            CPrintToChat(client, "    Knifes=%i Noscopes=%i Jumpshots=%i Grenades=%i", this.session.knife_kills, this.session.noscopes, this.session.jumpshots, this.session.grenade_kills);
        }
        CPrintToChat(client, "    KD=%.1f Accuracy=%.2f Headshots=%i", this.session.kd(), this.session.accuracy(), this.session.headshots);
    }
    
    void overall_stats(int client, bool kill_types=false, bool verbose=false) {
        CPrintToChat(client, "{white}Overall Stats:{default}");
        if(verbose) {
            CPrintToChat(client, "    Kills=%i Deaths=%i Damage=%i XP=%i", this.session.kills + this.start.kills, this.session.deaths + this.start.deaths, this.session.damage + this.start.damage, this.session.xp + this.start.xp);
        }
        if(kill_types) {
            CPrintToChat(client, "    Knifes=%i Noscopes=%i Jumpshots=%i Grenades=%i", this.session.knife_kills + this.start.knife_kills, this.session.noscopes + this.start.noscopes, this.session.jumpshots + this.start.jumpshots, this.session.grenade_kills + this.start.grenade_kills);
        }
        CPrintToChat(client, "    KD=%.1f Accuracy=%.2f Headshots=%i", this.start.overall_kd(this.session.kills, this.session.deaths), this.start.overall_accuracy(this.session.hits, this.session.shots), this.session.headshots + this.start.headshots);
    }
    
    
}

public void UpdateStatsCallback(Database db, DBResultSet result, const char[] error, int client) {
    if(strlen(error) > 0) {
        LogToFile(XP_LOG_FILE, "Error in update stats: %s", error);
        return;
    }
    if(result.AffectedRows == 0) {
        char query[128];
        Format(query, sizeof(query), "SELECT xp FROM pro_xp WHERE steamid = '%s'", steam_ids[client]);
        db.Query(UpdateStatsFailed, query, client);
    }
}

public void UpdateStatsFailed(Database db, DBResultSet result, const char[] error, int client) {
    if(strlen(error) > 0) {
        LogToFile(XP_LOG_FILE, "Error in update stats xp check: %s", error);
    } else if(result != null && result.FetchRow()) {
        int exp = result.FetchInt(0);
        if(player_xp[client] > exp) {
            LogToFile(logfile, "ERROR: user xp failed but database xp is smaller (user gained xp since query?) - client=%N from %ixp to %ixp", client, player_xp[client], exp);
        // } else if (player_xp[client] == exp) {
        //     LogAction(client, -1, "Update for client %i - old xp is equal to new xp", client);
        } else {
            // There was a discrepancy between the xp in memory and in the database; the database xp was lager which should would have otherwise subtracted from the player's xp
            LogToFile(logfile, "Stat update failed - attempted to update client %i (steamid=%s) xp from a lesser amount of %i to %i", client, steam_ids[client], player_xp[client], exp);
        }
    }
}

Players player_stats[MAXPLAYERS];
