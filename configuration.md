
# Configuration

## Hardcoded Configuration

There are some configuration options hard-coded into the `include/pro_xp/config.inc` file.  To modify them, edit the config file and recompile.

Sounds are off by default but can be enabled by modifying the config file with `SOUNDS_ENABLED` set to `true` and changing the `sound_level_up` and `sound_level_up_high` variables to point to sound files in the `cstrike/sound` folder.

### XP Calculation Configuration

The amount of XP gained is found by applying multipliers to the amount of damage dealt then and adding xp bonuses.

The default XP formula used is logarithmic.  With defaults level 100 will require 13 million xp.  Levels are reached faster initially but require an increasing amount of xp to reach each level.  The xp formula can be modified by tweaking the constants `A` and `B`.  If desired, the default formula can be replaced entirely by modifying the `level()` and `exp_points()` functions.

#### XP Multipliers

- Killshot, default: *1.1* (110% of normal xp)
- Headshot, default: *1.3*
- Bot multipliers - see the [bot_difficulty cvar](https://developer.valvesoftware.com/wiki/List_of_CS:S_Cvars#B):
  - easy difficulty, default: *0.28* (28% of normal xp)
  - normal difficulty, default: *0.32*
  - hard difficulty, default: *0.36*
  - expert difficulty, *0.45*
- Weapon modifiers: uses the `WeaponBonuses()` function to set multipliers on a per-weapon basis.  The defaults attempt to compensate for some weapons being overpowered and others harder to get hits with (like the scout).

#### XP Bonuses

- Noscope (if ProZoom is running; only applies to sniper rifles), default: *70*
- Jumpshot (if you shoot an emeny while in the air), default: *50*
- Airborne enemy (if you shoot an enemy that is in the air), default: *35*

## ConVars

- `sm_xp_dump_file`: the file to dump current xp stats to when using `dumpxp` console command.  Defaults to "logs/pro_xp_dump.txt" which will create a log in the sourcemod logs folder.
