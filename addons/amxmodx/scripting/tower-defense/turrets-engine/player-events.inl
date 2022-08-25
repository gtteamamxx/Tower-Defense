#if defined _towerdefense_turrets_player_events_included
  #endinput
#endif
#define _towerdefense_turrets_player_events_included

public registerPlayerEvents()
{
    RegisterHamPlayer(Ham_Killed, "@onPlayerKilled")
}

public client_disconnected(id)
{
    // when disconnected we don't want his turrets anymore
    removeAllPlayerTurrets(id);
}

@onPlayerKilled(id)
{
    // when player is killed and he was just moving turret
    // remove it
    removeMovingTurretForPlayer(id);
}