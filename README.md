# Pro XP

A flexible stats tracker and xp-based level system.  It was designed to be a slimmer replacement for something like `rankme` while also adding xp.  A set of natives are provided for querying level/xp information.

In addition to XP it also tracks kills, deaths, damage dealt, knife kills, noscopes (if ProZoom is running), jumpshots, grenade kills, KD ratio, accuracy, and headshots.  Stats are tracked both per-session (from join to disconnect) and overall.

This plugin will use clan tags to display the user's level.  For players reaching the level cap (defaults to 100), special tags can be displayed.

If Pro Zoom is running noscopes will give extra xp and track noscopes.

If Pro Sprint is running it will give bonus stamina depending on your level.

Also for users of Little Anticheat, XP can be deducted if the user is caught cheating.  Amounts can be configured in the `include/pro_xp/config.inc` file.

## Commands

- `!level`: displays your current level progress

- `!rankings` or `!top`: displays the overall rankings based on XP

- `!myrank` or `!rank`: shows where you are ranked overall based on XP

- `!xphelp`

- Stats
  
  - `!stats` or `!statistics`: by default shows KD, accuracy, and kills for both current session and overall
  - `!stats help`: shows options for displaying statistics
  - `!stats --all`: shows more detailed statistics
  - `!morestats`: same as `!stats --all`
  - `!session`: displays stats for the current session (uses same options described in `!stats help`)
  - `!overall`: displays overall stats (uses same options described in `!stats help`)

- Console commands
  
  - `dumpxp`: dumps the all xp stats to a file
  - `listxp`: lists all xp stats in the console

## Configuration

There are some configuration options hardcoded into the `include/pro_xp/config.inc` file.  To modify them, edit the config file and recompile.

Sounds are off by default but can be enabled by modifying the config file with `SOUNDS_ENABLED` set to `true` and changing the `sound_level_up` and `sound_level_up_high` variables to point to sound files in the `cstrike/sound` folder.

### XP Calculation Configuration

The default XP formula used is logarithmic.  With defaults level 100 will require 13 million xp.  Levels are reached faster initially but require an increasing amount of xp to reach each level.  The xp formula can be modified by tweaking the constants `A` and `B`.  If desired, the default formula can be replaced entirely by modifying the `level()` and `exp_points()` functions.

The amount of XP gained is found by applying multipliers to the amount of damage dealt then and adding xp bonuses.

#### XP Multipliers

- Killshot, default: 1.1 (110% of normal xp)
- Headshot, default: 1.3
- Bot multipliers (see the [bot_difficulty cvar](https://developer.valvesoftware.com/wiki/List_of_CS:S_Cvars#B):
  - easy difficulty, default: 0.28 (28% of normal xp)
  - normal difficulty, default: 0.32
  - hard difficulty, default: 0.36
  - expert difficulty, 0.45
- Weapon modifiers: uses the `WeaponBonuses()` function to set multipliers on a per-weapon basis.  The defaults attempt to compensate for some weapons being overpowered and others harder to get hits with (like the scout).

#### XP Bonuses

- Noscope (if ProZoom is running; only applies to sniper rifles), default: 70
- Jumpshot (if you shoot an emeny while in the air), default: 50
- Airborne enemy (if you shoot an enemy that is in the air), default: 35

## Installation

Installation is fairly simple: 

- modify your `databases.cfg` file
- then copy the .smx file to the plugins folder (e.g. `cstrike/addons/sourcemod/plugins`) and load the file using `sm plugins load`.

The table should be created automatically (only tested with MySQL, but should work with Postgres and SQLite).  If you have problems create the table manually instead of allowing the plugin the create the table.

Add the following to your `cstrike/addons/sourcemod/configs/databases.cfg`, substituting your database information and credentials:

```
  "pro_xp"
    {
        "driver"            "default"
        "host"                "<hostname>"
        "database"        "<database>"
        "user"                "<username>"
        "pass"                "<password>"
    }
```

The database table will be created on first run, or you can manually create it.  Code for MySQL:

```
CREATE TABLE `pro_xp` (
  `id` int(11) NOT NULL,
  `steamid` varchar(32) DEFAULT NULL,
  `name` varchar(64) DEFAULT NULL,
  `xp` int(11) NOT NULL DEFAULT '0',
  `sxp` int(11) DEFAULT '0',
  `steam3` varchar(32) DEFAULT NULL,
  `deaths` int(11) NOT NULL DEFAULT '0',
  `kills` int(11) NOT NULL DEFAULT '0',
  `hits` int(11) NOT NULL DEFAULT '0',
  `shots` int(11) NOT NULL DEFAULT '0',
  `jumpshots` int(11) NOT NULL DEFAULT '0',
  `noscopes` int(11) NOT NULL DEFAULT '0',
  `knife_kills` int(11) NOT NULL DEFAULT '0',
  `headshots` int(11) NOT NULL DEFAULT '0',
  `damage` bigint(11) NOT NULL DEFAULT '0',
  `grenade_kills` int(11) NOT NULL DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

ALTER TABLE `pro_xp`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `steamid_unique` (`steamid`);

ALTER TABLE `pro_xp`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=1
```

Automatically creating the tables has only been tested with MySQL, but should work for Postgres as well.
I do not know if automatic table creation will work with SQLite, but you can try it.

## ConVars

- `sm_xp_dump_file`: the file to dump current xp stats to when using `dumpxp` console command.  Defaults to "logs/pro_xp_dump.txt" which will create a log in the sourcemod logs folder.

## Plugins

Natives are provided to query player levels/xp, as well as two forwards: `OnGainXP` and `OnPlayerLevelUp`.  The `OnGainXP` forward is the most useful, allowing other plugins to get information on xp gained, jumpshots, noscopes, etc.

For instance, you could use it to display a message everytime someone gets a noscope kill:

```
public void OnGainXP(int client, int victim, int xp, int damage, bool killshot, bool headshot, bool noscope, bool jumpshot, bool grenade_hit) {
   // if noscope and killshot are both true then do something here
}
```

The `OnPlayerLevelUp` forward could, for example, display a notification when a user levels up:

```
public void OnPlayerLevelUp(int client, int oldLevel, int newLevel) {
  // client went from oldLevel to newLevel, display notification here
}
```

## Requirements

- morecolors.inc

## Todo

- Add season rankings
