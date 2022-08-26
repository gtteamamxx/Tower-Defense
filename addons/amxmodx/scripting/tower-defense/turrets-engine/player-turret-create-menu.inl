#if defined _towerdefense_turrets_player_turret_create_menu_included
  #endinput
#endif
#define _towerdefense_turrets_player_turret_create_menu_included

public startCreatingTurretForPlayer(id, turretKey[33])
{
    // show player menu to create turret here
    @showPlayerCreateHereMenu(id, turretKey);

    // create turret to allow player select position
    createTurretForCreationForPlayer(id, turretKey);
}

@showPlayerCreateHereMenu(id, turretKey[33])
{
    // get turret name
    new turretName[33];
    getTurretName(turretKey, turretName);

    // create menu
    new menuTitle[64];
    formatex(menuTitle, 63, "You are creating turret: %s", turretName);

    new menu = menu_create(menuTitle, "@onPlayerTurretCreatePlaceHere");

    menu_additem(menu, "\rPlace it here", .info = turretKey);

    // show menu for user
    menu_display(id, menu);
}

@onPlayerTurretCreatePlaceHere(id, menu, item)
{
    // if player somehow died
    if (!is_user_alive(id))
    {
        return;
    }

    // create turret
    if (item == 0)
    {
        new selectedTurretKey[33], name[3];
        new access, cb;

        // get selected turret key
        menu_item_getinfo(menu, item, access, selectedTurretKey, 32, name, 2, cb);

        // check if turret can be placed at current position
        new bool:canBePlacedAtCurrentPosition = @canPlayerCreateTurret(id);

        // if turret can not be placed here
        // show menu again
        if (!canBePlacedAtCurrentPosition)
        {
            @showPlayerCreateHereMenu(id, selectedTurretKey);
        }
        else
        {
            @createTurretHere(id, selectedTurretKey);
        }
    }

    // if user went back
    if (item == MENU_EXIT) 
    {
        // remove turret which he was creating
        removeMovingTurretForPlayer(id);

        // open previous menu
        openTurretsMenu(id);
    }

    // free menu handler
    menu_destroy(menu);
}

@createTurretHere(id, turretKey[33])
{
    createTurretForPlayer(id, turretKey);
}

bool:@canPlayerCreateTurret(id)
{
    // get moving turret
    new turretEntity;
    CED_GetCell(id, CED_PLAYER_MOVING_TURRET_ENTITY_KEY, turretEntity);

    // check if turret can be placed at current position
    new bool:canBePlacedAtCurrentPosition;
    CED_GetCell(turretEntity, CED_ENTITY_PLACE_POSIBILITY_KEY, canBePlacedAtCurrentPosition);

    return canBePlacedAtCurrentPosition;
}