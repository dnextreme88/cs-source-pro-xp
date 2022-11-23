
# Installation

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
