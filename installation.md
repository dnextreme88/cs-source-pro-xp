
# Installation

Installation is fairly simple: 

1. First, get a dedicated server. You can follow the instructions at this [Steam tutorial](https://steamcommunity.com/sharedfiles/filedetails/?id=397365275).

2. Download [SourceMod](https://www.sourcemod.net/downloads.php) and extract the contents to your dedicated server's cstrike directory

3. Go to `/addons/sourcemod/configs` and modify `databases.cfg` file. Add the following lines just before the final closing brace.
   
   ```
     "pro_xp"
       {
           "driver"      "default"
           "host"        "<hostname>"
           "database"    "<database>"
           "user"        "<username>"
           "pass"        "<password>"
       }
   ```

4. Clone this repository then extract `ProXP.sp` and the `include/` directory to `/addons/sourcemod/scripting`.

5. Compile `ProXP.sp` file by dragging it to `compile.exe`. Go to the `compiled/` directory of the same folder and copy the `ProXP.smx` file to the plugins folder (e.g. `/addons/sourcemod/plugins`)

6. On your dedicated server's console, load the plugin with `sm plugins load ProXP.smx` to load it individually or `sm plugins unload_all` then `sm plugins refresh` to refresh all your plugins.

The table should be created automatically on first run (only tested with MySQL, but should work with Postgres and SQLite). If you have problems, see [Database Setup](db_setup.md).

For available commands, please see [Commands](commands.md). Enjoy!
