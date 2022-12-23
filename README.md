# Introduction

This is based from the [original ProXP repo](https://github.com/vishusandy/ProXP) by [vishusandy](https://github.com/vishusandy), adding support for bots, along with new fields that track number of games the player has joined in the server, and records first kill (first blood) that a player makes every round.

Read the original [README.md](README_original.md) for more information such as commands, and how to properly setup the database.

## Differences

There's not much of a difference from the original repository except for the following:

- Added new field `games_count` that tracks the number of games the players and the bots have played on the server.

- Added new field `first_bloods` that tracks every first kill a player has made every round.

- Added support for bots, which will always have **BOT** as their `steamid` in the DB.

- Fixed code readability and alignment, making it easier to read and adapt new changes.

## Installation

See [installation](installation.md).

## Dependencies

- [morecolors.inc](https://forums.alliedmods.net/showthread.php?t=185016) (included)
- Optional - [ProSprint](https://github.com/vishusandy/ProSprint): gives stamina bonus depending on your level
- Optional - [ProZoom](https://github.com/vishusandy/ProZoom): gives xp bonus for noscope hits

## Contributions

Contributions are welcome! Please create a new branch and make a pull request to the main branch so that I'll review the changes and approve it if it's beneficial enough.

## Credits

- Special thanks to vishusandy for his original work.
- To Valve for making a wonderful game.
- To Dr. McKay from the SourceMod community for creating morecolors.inc.
- To the Sourcemod community for making it possible to create and play Counter-Strike: Source with plugins.
