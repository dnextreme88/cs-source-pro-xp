#if defined _pro_xp_commands_included
    #endinput
#endif
#define _pro_xp_commands_included


public Action CommandLevel(client, args) {
    if (!enabled || levels[client] == 0) {
        return Plugin_Continue;
    }
    char xp_buff[16];
    NumberFormat(player_xp[client], xp_buff, sizeof(xp_buff));
    CPrintToChatAll("%N is at level {green}%i{default} with %sxp", client, levels[client], xp_buff);
    int next_xp = next_levels[client] - player_xp[client];
    NumberFormat(next_xp, xp_buff, sizeof(xp_buff));
    CPrintToChatAll("{red}%s{default}xp is needed to reach level %i", xp_buff, levels[client] + 1);
    return Plugin_Continue;
}

// Do nothing, just close the menu
public int HandleLevelRanking(Menu menu, MenuAction action, int param1, int param2) {
    return 0;
}

public Action ShowLevelRanking(int client, int args) {
    if (!enabled || !IsClientInGame(client) || IsFakeClient(client)) {
        return Plugin_Continue;
    }

    char query[] = "SELECT name, xp FROM pro_xp ORDER BY xp DESC";
    DB.Query(ShowLevelRankCallback, query, client);

    return Plugin_Continue;
}

public void ShowLevelRankCallback(Database db, DBResultSet result, const char[] error, int client) {
    if (strlen(error) > 0) {
        LogToFile(logfile, "Show level rank callback error: %s", error);
        return;
    }

    if (!enabled || client == 0 || !IsClientInGame(client) || result == null) {
        return;
    }

    Menu menu = new Menu(HandleLevelRanking);
    menu.SetTitle("Level Ranking");

    char namebuff[128];
    char buff[MAX_NAME_LENGTH];
    char xp_buff[32];
    int fetched = 0;
    int rank = 1;
    while (fetched < LIST_RANK_LIMIT && result.FetchRow()) {
        int xp = SQL_FetchInt(result, 1);
        SQL_FetchString(result, 0, namebuff, sizeof(namebuff));
        NumberFormat(xp, xp_buff, sizeof(xp_buff));
        Format(buff, sizeof(buff), "#%i [L%i] %s - %sxp", rank, level(xp), namebuff, xp_buff);
        menu.AddItem("", buff);
        fetched += 1;
        rank += 1;
        fetched += 1;
    }

    menu.Display(client, RANK_MENU_TIME);
}


// Todo: figure out how to make season data portable
// public Action ShowSeasonLevelRanking(int client, int args) {
//     if (!enabled || !IsClientInGame(client) || IsFakeClient(client)) {
//         return Plugin_Continue;
//     }

//     char query[] = "SELECT name, xp - sxp as SeasonXP FROM pro_xp ORDER BY SeasonXP DESC";
//     DB.Query(ShowSeasonLevelRankCallback, query, client);
//     return Plugin_Continue;
// }

// public void ShowSeasonLevelRankCallback(Database db, DBResultSet result, const char[] error, int client) {
//     if (strlen(error) > 0) {
//         LogToFile(logfile, "Show level rank callback error: %s", error);
//         return;
//     }

//     if (!enabled || client == 0 || !IsClientInGame(client) || result == null) {
//         return;
//     }

//     Menu menu = new Menu(HandleLevelRanking);
//     menu.SetTitle("Season Level Ranking");

//     char namebuff[64];
//     char buff[MAX_NAME_LENGTH];
//     char xp_buff[16];
//     int fetched = 0;
//     int rank = 1;
//     while (fetched < LIST_RANK_LIMIT && result.FetchRow()) {
//         int xp = SQL_FetchInt(result, 1);
//         SQL_FetchString(result, 0, namebuff, sizeof(namebuff));
//         NumberFormat(xp, xp_buff, sizeof(xp_buff));
//         Format(buff, sizeof(buff), "#%i [L%i] %s - %sxp", rank, level(xp), namebuff, xp_buff);
//         menu.AddItem("", buff);
//         fetched += 1;
//         rank += 1;
//     }

//     menu.Display(client, RANK_MENU_TIME);
// }


public Action ShowPersonalRank(int client, int args) {
    if (!enabled || !IsClientInGame(client) || IsFakeClient(client)) {
        return Plugin_Continue;
    }

    char query[384];
    Format(query, sizeof(query), "SELECT a.name, a.xp, (SELECT COUNT(*) FROM pro_xp b WHERE a.xp < b.xp )+1 AS rank, (SELECT COUNT(*) FROM pro_xp c) AS count FROM pro_xp a WHERE steamid = '%s'", steam_ids[client]);
    DB.Query(ShowPersonalRankCallback, query, client);

    return Plugin_Continue;
}

public void ShowPersonalRankCallback(Database db, DBResultSet result, const char[] error, int client) {
    if (strlen(error) > 0) {
        LogToFile(logfile, "Show level rank callback error: %s", error);
        return;
    }

    if (!enabled || client == 0 || !IsClientInGame(client) || result == null || !result.FetchRow()) {
        return;
    }

    char name[MAX_NAME_LENGTH];
    SQL_FetchString(result, 0, name, sizeof(name));
    int xp = SQL_FetchInt(result, 1);
    int rank = SQL_FetchInt(result, 2);
    int count = SQL_FetchInt(result, 3);
    char xp_buff[16];
    NumberFormat(xp, xp_buff, sizeof(xp_buff));
    CPrintToChatAll("{red}%s{default} is ranked {green}%i{default} out of {green}%i{default} with {orange}%s{default}xp", name, rank, count, xp_buff);
}

public Action ShowStats(int client, int args) {
    bool kill_types = false;
    bool verbose = false;
    if (!get_stat_flags(client, args, kill_types, verbose)) {
        return Plugin_Continue;
    }

    player_stats[client].stats(client, kill_types, verbose);

    return Plugin_Continue;
}

public Action ShowSession(int client, int args) {
    bool kill_types = false;
    bool verbose = false;
    if (!get_stat_flags(client, args, kill_types, verbose)) {
        return Plugin_Continue;
    }

    player_stats[client].session_stats(client, kill_types, verbose);

    return Plugin_Continue;
}

public Action ShowOverallStats(int client, int args) {
    bool kill_types = false;
    bool verbose = false;
    if (!get_stat_flags(client, args, kill_types, verbose)) {
        return Plugin_Continue;
    }

    player_stats[client].overall_stats(client, kill_types, verbose);

    return Plugin_Continue;
}

public Action ShowMoreStats(int client, int args) {
    bool kill_types = (args == 0)? true: false;
    bool verbose = (args == 0)? true: false;
    if (!get_stat_flags(client, args, kill_types, verbose)) {
        return Plugin_Continue;
    }

    player_stats[client].stats(client, kill_types, verbose);

    return Plugin_Continue;
}


bool get_stat_flags(int client, int args, bool &kill_types, bool &verbose) {
    char buffer[24];
    if (args > 0 && args <= 10) {
        for (int i = 1; i <= args; i++) {
            GetCmdArg(1, buffer, sizeof(buffer));

            if (StrEqual(buffer, "--verbose", false)) {
                verbose = !verbose;
            } else if (StrEqual(buffer, "--extended", false) || StrEqual(buffer, "--kills", false)) {
                kill_types = !kill_types;
            } else if (StrEqual(buffer, "--all", false)) {
                kill_types = !kill_types;
                verbose = !verbose;
            } else if (StrEqual(buffer, "help", false)) {
                GetCmdArg(0, buffer, sizeof(buffer));
                stat_help(client, buffer);

                return false;
            }
        }
    }

    return true;
}


void stat_help(int client, const char[] cmd) {
    ReplyToCommand(client, "%s: [--all|--verbose|--extended|--kills]", cmd);
    ReplyToCommand(client, "\x07ffffff  --extended / --kills\x01 shows extended kill stats");
    ReplyToCommand(client, "\x07ffffff  --verbose\x01 shows deaths, xp, and damage");
}


public Action ShowLevelHelp(int client, int args) {
    PrintToChat(client, "Commands: !level, !statistics, !session, !overall, !rankings, !myrank, !xphelp");
    return Plugin_Continue;
}

public Action DumpXP(int args) {
    char buffer[8];
    bool show_all = true;
    if (GetCmdArgs() > 0) {
        GetCmdArg(1, buffer, sizeof(buffer));
        show_all = (StrEqual(buffer, "0") || StrEqual(buffer, "false", false) || StrEqual(buffer, "list", false))? false: true;
    }
    DB.Query(DumpXPCallback, "SELECT steamid, name, xp FROM pro_xp", show_all);
    return Plugin_Continue;
}

public Action ListXP(int args) {
    DB.Query(DumpXPCallback, "SELECT steamid, name, xp FROM pro_xp", false);
    return Plugin_Continue;
}

public void DumpXPCallback(Database db, DBResultSet result, const char[] error, bool show_all) {
    if (strlen(error) > 0) {
            LogToFile(logfile, "Database error occurred when dumping xp: '%s'", error);
    }

    if (result != null) {
        char cvar_buffer[PLATFORM_MAX_PATH];
        GetConVarString(dump_file, cvar_buffer, sizeof(cvar_buffer));
        char file_buffer[PLATFORM_MAX_PATH];
        BuildPath(Path_SM, file_buffer, PLATFORM_MAX_PATH, cvar_buffer);

        File xpfile;
        if (show_all == true) {
            xpfile = OpenFile(file_buffer, "w");
        }

        char steamid[32];
        char name[64];
        LogToFile(logfile, "STEAMID\tNAME\tDB-XP\tInMem-XP");
        char line_buffer[256];
        while (result.FetchRow()) {
            result.FetchString(0, steamid, sizeof(steamid));
            result.FetchString(1, name, sizeof(name));
            int db_xp = result.FetchInt(2);

            if (show_all == false) {
                for (int i = 1; i <= MaxClients; i++) {
                    if (IsClientInGame(i) && StrEqual(steamid, steam_ids[i])) {
                        if (db_xp > player_xp[i]) {
                            // database mismatch
                        }
                        break;
                    }
                }
            } else {
                Format(line_buffer, sizeof(line_buffer), "%s\t%s\t%i\t-", steamid, name, db_xp);
                xpfile.WriteString(line_buffer, false);
            }
        }
        if (show_all == true) {
            LogToFile(logfile, "Dumped xp to '%s'", file_buffer);
            delete xpfile;
        }
    }
}
