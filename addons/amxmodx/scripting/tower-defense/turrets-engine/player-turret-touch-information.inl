#if defined _towerdefense_turrets_player_touch_informations
  #endinput
#endif
#define _towerdefense_turrets_player_touch_informations

public registerEventsForPlayerTurretTouchInformations()
{
    register_touch(TURRET_CLASSNAME, "player", "@showInformationAboutTurret");
}

@showInformationAboutTurret(ent, id)
{
    new touchedTurretEntByPlayer = getPlayerTouchingTurret(id);

    // player is now touching turret
    if (touchedTurretEntByPlayer != ent)
    {
        // store information about tocuhed turret
        CED_SetCell(id, CED_PLAYER_TOUCHING_TURRET_ENTITY_KEY, ent);

        // set task to remove information of touched turret
        new parameters[2];
        parameters[0] = id;
        parameters[1] = ent;

        set_task(1.0, "@resetInformationAboutTouchedTurretByPlayer", .parameter = parameters, .len = 2);

        // show hud information
        @showHudInformationAboutTurret(id, ent);

        // refresh turret menu if is displayed
        refreshTurretDetailMenuIfPlayerStillHaveItOpened(ent);
    }
}

@showHudInformationAboutTurret(id, ent)
{
    // get turret owner
    new ownerId = getTurretOwner(ent);

    // if touching player is not owner then don't anyting
    if (id == ownerId) 
    { 
        @showOwnerTurretInformation(ownerId, ent);
    }
    else
    {
        set_dhudmessage(255, 255, 255, -1.0, 0.74, 0, 0.5, 1.0);
        show_dhudmessage(id, "It is not your turret");
    }
}

@showOwnerTurretInformation(id, ent)
{
    new szTouchedTurretInfo[128];
    formatex(szTouchedTurretInfo, 127, "Yourt turret");

    if (!isTurretEnabled(ent))
    {
        formatex(szTouchedTurretInfo, 127, "%s^nDISABLED", szTouchedTurretInfo);
    }
    else
    {
        formatex(szTouchedTurretInfo, 127, "%s^nAMMO: %d", szTouchedTurretInfo, getTurretAmmo(ent));

        if (isTurretReloading(ent))
        {
            formatex(szTouchedTurretInfo, 127, "%s - RELOADING!", szTouchedTurretInfo, getTurretAmmo(ent));
        }
        if (isLowAmmoOnTurret(ent))
        {
            formatex(szTouchedTurretInfo, 127, "%s [LOW AMMO]", szTouchedTurretInfo, getTurretAmmo(ent));
        }
        else if(isTurretEmpty(ent))
        {
            formatex(szTouchedTurretInfo, 127, "%s [EMPTY]", szTouchedTurretInfo, getTurretAmmo(ent));
        }

        // if turret detail menu is not opened for turret
        if (getShowedTurretEntInDetailMenu(id) != ent)
        {
            formatex(szTouchedTurretInfo, 127, "%s^nPRESS 'E' TO OPEN MENU", szTouchedTurretInfo);
        }
    }

    set_dhudmessage(255, 255, 255, -1.0, 0.74, 0, 0.5, 1.0);
    show_dhudmessage(id, szTouchedTurretInfo);
}

@resetInformationAboutTouchedTurretByPlayer(parameters[2])
{
    new id = parameters[0];
    new touchedTurret = parameters[1];

    CED_SetCell(id, CED_PLAYER_TOUCHING_TURRET_ENTITY_KEY, -1);
}