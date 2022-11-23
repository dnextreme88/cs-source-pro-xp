# Plugin Interface

Natives are provided to query player levels/xp, as well as two forwards: `OnGainXP` and `OnPlayerLevelUp`. The `OnGainXP` forward is the most useful, allowing other plugins to get information on xp gained, jumpshots, noscopes, etc.

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
