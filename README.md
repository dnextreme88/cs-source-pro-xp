# Pro XP

A flexible stats tracker and xp-based level system for Counter-Strike Source.

Only works for CSS at the moment but shouldn't be hard to make compatible with CSGO (if you are willing to help with this let me know).

## Overview

ProXP was designed to be a slimmer replacement for something like `rankme` while also adding xp.  In addition to XP it also tracks kills, deaths, damage dealt, knife kills, noscopes (if [ProZoom](https://github.com/vishusandy/ProZoom) is running), jumpshots, grenade kills, KD ratio, accuracy, and headshots.  Stats are tracked both per-session (from join to disconnect) and overall.

This plugin will use clan tags to display the user's level.  For players reaching the level cap (defaults to 100), special tags can be displayed.

## Features

- Per-session and overall stats tracking

- Level rankings

- If [ProZoom](https://github.com/vishusandy/ProZoom) is installed noscopes will give extra xp and track noscopes.

- If [ProSprint](https://github.com/vishusandy/ProSprint) is installed it will give bonus stamina depending on your level.

- A set of natives are provided for querying level/xp information from other plugins.

- Also for users of [Little Anti-Cheat](https://github.com/J-Tanzanite/Little-Anti-Cheat), XP is deducted if the user is caught cheating.  Amounts can be configured in the `include/pro_xp/config.inc` file and requires recompiling.

## Commands

- `!level`: displays your current level progress

- `!rankings` or `!top`: displays the overall rankings based on XP

- `!myrank` or `!rank`: shows where you are ranked overall based on XP

- `!xphelp`: show xp related commands

- Stats
  
  - `!stats` or `!statistics`: by default shows KD, accuracy, and kills for both current session and overall
    - Syntax: `!stats [--all|--verbose|--extended|--kills]`
  - `!stats help`: shows options for displaying statistics
  - `!stats --all`: shows all statistics
  - `!morestats`: same as `!stats --all`
  - `!session`: displays stats for the current session (uses same options described in `!stats help`)
  - `!overall`: displays overall stats (uses same options described in `!stats help`)

- Console commands
  
  - `dumpxp`: dumps the all xp stats to a file
  - `listxp`: lists all xp stats in the console

## Configuration

There are some configuration options hard-coded into the `include/pro_xp/config.inc` file.  To modify them, edit the config file and recompile.

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

1. modify your `databases.cfg` file
   
   ```
     "pro_xp"
       {
           "driver"      "default"
           "host"        "<hostname>"
           "database"    "<database>"
           "user"        "<username>"
           "pass"        "<password>"
       }
   ```

2. then copy the .smx file to the plugins folder (e.g. `cstrike/addons/sourcemod/plugins`)

3. load the plugin (e.g. `sm plugins load filename.smx`)

The table should be created automatically on first run (only tested with MySQL, but should work with Postgres and SQLite).  If you have problems see [Database Setup](db_setup.md).

## ConVars

- `sm_xp_dump_file`: the file to dump current xp stats to when using `dumpxp` console command.  Defaults to "logs/pro_xp_dump.txt" which will create a log in the sourcemod logs folder.

## Plugin Interface

See [Plugin Interface](interface.md) for information on how to interact with ProXP using other plugins.

## Dependencies

- [morecolors.inc](https://forums.alliedmods.net/showthread.php?t=185016)

## Todo

- Add seasonal rankings
