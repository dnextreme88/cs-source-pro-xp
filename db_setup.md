# Database Setup

## Setup

1. Add the following to your `cstrike/addons/sourcemod/configs/databases.cfg`

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

2. The table will be created automatically on first run. If you have issues see [Manual Setup](db_setup.md#manual-setup).
   
   > Note: automatically creating the tables has only been tested with MySQL, but should work for Postgres and SQLite as well.

## Manual Setup

If you have problems you can create the table manually.  Code for MySQL:

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
