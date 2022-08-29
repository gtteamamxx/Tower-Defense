#if defined _towerdefense_turrets_player_events_included
  #endinput
#endif
#define _towerdefense_turrets_player_events_included

public registerPlayerEvents()
{
    RegisterHamPlayer(Ham_Killed, "@onPlayerKilled")

    registerEventsForPlayerTurretTouchInformations();
    registerEventsForShowTurretDetailMenu();
}

public client_disconnected(id)
{
    // when disconnected we don't want his turrets anymore
    removeAllPlayerTurrets(id);

    // also player can't touch any turret anymore
    CED_SetCell(id, CED_PLAYER_TOUCHING_TURRET_ENTITY_KEY, -1);
}

@onPlayerKilled(id)
{
    // when player is killed and he was just moving turret
    // remove it
    removeMovingTurretForPlayer(id);
}