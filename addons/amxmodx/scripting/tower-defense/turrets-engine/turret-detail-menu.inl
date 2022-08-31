#if defined _towerdefense_turret_detail_menu_included
  #endinput
#endif
#define _towerdefense_turret_detail_menu_included

public registerEventsForShowTurretDetailMenu()
{
    register_forward(FM_CmdStart, "@onUseCommandExecute");
}

public refreshTurretDetailMenuIfPlayerStillHaveItOpened(ent)
{
    new ownerId = getTurretOwner(ent);

    // if current turret entity from menu for player is same as argument
    // refresh current player menu by opening it again
    if (getShowedTurretEntInDetailMenu(ownerId) == ent)
    {
        showTurretDetailMenu(ownerId, ent);
    }
}

public showTurretDetailMenu(id, ent)
{
    // if turret menu is already showed, clear it first and open 
    // new with refreshed information
    if (getShowedTurretEntInDetailMenu(id) != -1) 
    {
        @hideCurrentlyShowedTurretMenu(id);
    }

    // clear rangers if player had menu open and a new menu with another turret is opened
    @hidePreviousRangersIfNewMenuIsOpened(id, ent);

    // initialize menu
    static szHeader[320];
    @getMenuHeader(id, ent, szHeader);

    new menu = menu_create(szHeader, "@onPlayerTurretDetailMenuSelected");
    new cb = menu_makecallback("@turretDetailMenuCallback");

    // Add increase damage option
    static szDamageItem[128];
    @getIncreaseDamageMenuOption(id, ent, szDamageItem);
    menu_additem(menu, szDamageItem, .callback = cb);

    // Add increase range option
    static szRangeItem[128];
    @getIncreaseRangeMenuOption(id, ent, szRangeItem);
    menu_additem(menu, szRangeItem, .callback = cb);

    // Add firerate option
    static szFirerateItem[128];
    @getIncreaseFirerateMenuOption(id, ent, szFirerateItem);
    menu_additem(menu, szFirerateItem, .callback = cb);

    // Add accuracy option
    static szAccuracyItem[128];
    @getIncreaseAccuracyMenuOption(id, ent, szAccuracyItem);
    menu_additem(menu, szAccuracyItem, .callback = cb);

    // Add agility option
    static szAgilityItem[128];
    @getIncreaseAgilityMenuOption(id, ent, szAgilityItem);
    menu_additem(menu, szAgilityItem, .callback = cb);

    // Add buy ammo option
    static szBuyAmmoItem[128];
    @getBuyAmmoOption(id, ent, szBuyAmmoItem);
    menu_additem(menu, szBuyAmmoItem, .callback = cb);

    // Add change shot mode option
    static szShotModeItem[128];
    @getChangeShotModeMenuOption(id, ent, szShotModeItem);
    menu_additem(menu, szShotModeItem);

    // store information about showed turret
    @saveInformationAboutOpenedTurretMenu(id, ent);

    // show ranger if player is not touching turret
    @showTurretRangersIfPlayerIsNotTouchingTurret(id, ent);

    // show menu for player
    menu_display(id, menu);
}

@showTurretRangersIfPlayerIsNotTouchingTurret(id, ent)
{
    // if player opened turret details menu and he's not touching this turret
    // then show ranger for new turret
	new touchedTurretEntity = getPlayerTouchingTurret(id);
	if (touchedTurretEntity != ent)
	{
		createAndAttachRangerToTurret(ent);
	}
}

@onUseCommandExecute(id, uc_handle, seed)
{
	// if user pressed 'E' button
    if((get_uc(uc_handle, UC_Buttons) & IN_USE) && !(get_user_oldbutton(id) & IN_USE))
    {
        new touchedTurretEntByPlayer = getPlayerTouchingTurret(id);

        // If touched turret is not exist/not valid, skip
        if(!is_valid_ent(touchedTurretEntByPlayer))
        {
            return;
        }

        // If touched turret is not owned by a player by user, skip
        if (getTurretOwner(touchedTurretEntByPlayer) != id)
        {
            return;
        }

        // We can open menu only if turret is activated and is not moved
        if(!isTurretMoving(touchedTurretEntByPlayer) && isTurretEnabled(touchedTurretEntByPlayer))
        {
            showTurretDetailMenu(id, touchedTurretEntByPlayer);
        }
    }
}

@getMenuHeader(id, ent, szHeader[320])
{
    new turretAmmo = getTurretAmmo(ent);
    static turretKey[33];
    getTurretKey(ent, turretKey)

    static turretName[33];
    getTurretName(turretKey, turretName);

    new turretDamageLevel = getCurrentTurretDamageLevel(ent);
    new Float:turretDamage[2];
    getCurrentTurretDamage(ent, turretDamage);

    new turretRangeLevel = getCurrentTurretRangeLevel(ent);
    new Float:turretRange[2];
    getCurrentTurretRange(ent, turretRange);

    new turretFirerateLevel = getCurrentTurretFirerateLevel(ent);
    new Float:turretFirerate[2];
    getCurrentTurretFirerate(ent, turretFirerate);

    new turretAccuracyLevel = getCurrentTurretAccuracyLevel(ent);
    new Float:turretAccuracy[2]; 
    getCurrentTurretAccuracy(ent, turretAccuracy);

    new turretAgilityLevel = getCurrentTurretAgilityLevel(ent);
    new Float:turretAgility[2]; 
    getCurrentTurretAgility(ent, turretAgility);

    static shotModeName[33];
    getCurrentTurretShotModeName(ent, shotModeName);

    formatex(szHeader, 319, "%s | AMMO: %d | SHOT MODE: %s", turretName, turretAmmo, shotModeName);
    format(szHeader, 319, "%s^nCurrent damage level: %d [%d ~ %d]", szHeader, turretDamageLevel, floatround(turretDamage[0]), floatround(turretDamage[1]));
    format(szHeader, 319, "%s^nCurrent range level: %d [%d ~ %d]", szHeader, turretRangeLevel, floatround(turretRange[0]), floatround(turretRange[1]));
    format(szHeader, 319, "%s^nCurrent firerate level: %d [%0.2fs ~ %0.2fs]", szHeader, turretFirerateLevel, turretFirerate[0], turretFirerate[1]);
    format(szHeader, 319, "%s^nCurrent accuracy level: %d [%d%% ~ %d%%]", szHeader, turretAccuracyLevel, floatround(turretAccuracy[0] * 100), floatround(turretAccuracy[1] * 100));
    format(szHeader, 319, "%s^nCurrent agility level: %d [%0.2fs ~ %0.2fs]", szHeader, turretAgilityLevel, turretAgility[0], turretAgility[1]);
}

@getIncreaseDamageMenuOption(id, ent, szOption[128])
{
	new turretKey[33];
	getTurretKey(ent, turretKey);

	new turretDamageLevel = getCurrentTurretDamageLevel(ent);

	formatex(szOption, 127, "Increase damage");

	if (isDamageLevelExist(turretKey, turretDamageLevel + 1))
	{
		new Float:turretDamage[2];
		getCurrentTurretDamage(ent, turretDamage);

		new Float:damageForNextLevel[2];
		getTurretDamageForLevel(turretKey, turretDamageLevel + 1, damageForNextLevel);

		format(szOption, 127, "%s [+%d ~ +%d]", szOption, 
			floatround(damageForNextLevel[0] - floatround(turretDamage[0])),
			floatround(damageForNextLevel[1] - floatround(turretDamage[1]))
		);
	}
	else
	{
		format(szOption, 127, "%s [MAX LEVEL REACHED]", szOption);
	}
}

@getIncreaseRangeMenuOption(id, ent, szOption[128])
{
	new turretKey[33];
	getTurretKey(ent, turretKey);

	new turretRangeLevel = getCurrentTurretRangeLevel(ent);

	formatex(szOption, 127, "Increase range");

	if (isRangeLevelExist(turretKey, turretRangeLevel + 1))
	{
		new Float:turretRange[2];
		getCurrentTurretRange(ent, turretRange);

		new Float:rangeForNextLevel[2];
		getTurretRangeForLevel(turretKey, turretRangeLevel + 1, rangeForNextLevel);

		format(szOption, 127, "%s [+%d ~ +%d]", szOption, 
			floatround(rangeForNextLevel[0] - floatround(turretRange[0])),
			floatround(rangeForNextLevel[1] - floatround(turretRange[1]))
		);
	}
	else
	{
		format(szOption, 127, "%s [MAX LEVEL REACHED]", szOption);
	}
}

@getIncreaseFirerateMenuOption(id, ent, szOption[128])
{
	new turretKey[33];
	getTurretKey(ent, turretKey);

	new turretFirerateLevel = getCurrentTurretFirerateLevel(ent);

	formatex(szOption, 127, "Increase firerate");

	if (isFirerateLevelExist(turretKey, turretFirerateLevel + 1))
	{
		new Float:turretFirerate[2];
		getCurrentTurretFirerate(ent, turretFirerate);

		new Float:firerateForNextLevel[2];
		getTurretFirerateForLevel(turretKey, turretFirerateLevel + 1, firerateForNextLevel);

		format(szOption, 127, "%s [-%0.2fs ~ -%0.2fs]", szOption, 
			turretFirerate[0] - firerateForNextLevel[0],
			turretFirerate[1] - firerateForNextLevel[1]
		);
	}
	else
	{
		format(szOption, 127, "%s [MAX LEVEL REACHED]", szOption);
	}
}

@getChangeShotModeMenuOption(id, ent, szOption[128])
{
    formatex(szOption, 127, "Change shot mode");
}

@getBuyAmmoOption(id, ent, szOption[128])
{
    new turretKey[33];
    getTurretKey(ent, turretKey);

    new reloadAmmo = getTurretReloadAmmo(turretKey);
    formatex(szOption, 127, "Buy %d ammo", reloadAmmo);
}

@getIncreaseAccuracyMenuOption(id, ent, szOption[128])
{
    new turretKey[33];
    getTurretKey(ent, turretKey);

    new turretAccuracyLevel = getCurrentTurretAccuracyLevel(ent);

    formatex(szOption, 127, "Increase accuracy");

    if (isAccuracyLevelExist(turretKey, turretAccuracyLevel + 1))
    {
        new Float:turretAccuracy[2];
        getCurrentTurretAccuracy(ent, turretAccuracy);

        new Float:accuracyForNextLevel[2];
        getTurretAccuracyForLevel(turretKey, turretAccuracyLevel + 1, accuracyForNextLevel);

        format(szOption, 127, "%s [+%d%% ~ +%d%%]", szOption, 
            floatround((accuracyForNextLevel[0] - turretAccuracy[0]) * 100.0),
            floatround((accuracyForNextLevel[1] - turretAccuracy[1]) * 100.0)
        );
    }
    else
    {
        format(szOption, 127, "%s [MAX LEVEL REACHED]", szOption);
    }
}

@getIncreaseAgilityMenuOption(id, ent, szOption[128])
{
    new turretKey[33];
    getTurretKey(ent, turretKey);

    new turretAgilityLevel = getCurrentTurretAgilityLevel(ent);

    formatex(szOption, 127, "Increase agility");

    if (isAgilityLevelExist(turretKey, turretAgilityLevel + 1))
    {
        new Float:turretAgility[2];
        getCurrentTurretAgility(ent, turretAgility);

        new Float:agilityForNextLevel[2];
        getTurretAgilityForLevel(turretKey, turretAgilityLevel + 1, agilityForNextLevel);

        format(szOption, 127, "%s [-%0.2fs ~ -%0.2fs]", szOption, 
            turretAgility[0] - agilityForNextLevel[0],
            turretAgility[1] - agilityForNextLevel[1]
        );
    }
    else
    {
        format(szOption, 127, "%s [MAX LEVEL REACHED]", szOption);
    }
}

@turretDetailMenuCallback(id, menu, item)
{
    // player can upgrade turret only when is staying near it
    new touchedTurret = getPlayerTouchingTurret(id);
    new menuTurret = getShowedTurretEntInDetailMenu(id);

    if (touchedTurret != menuTurret)
    {
        return ITEM_DISABLED;
    }

    return ITEM_ENABLED;
}

@onPlayerTurretDetailMenuSelected(id, menu, item)
{    
    new turretEntity = getShowedTurretEntInDetailMenu(id);

    // if player escaped from menu and he's not touching
    // then hide ranger
    @hideTurretRangersIfPlayerIsNotTouchingTurret(id);
    @saveInformationAboutOpenedTurretMenu(id, -1);

    // hide menu
    menu_destroy(menu);

    if(item == MENU_EXIT) 
    {
        return PLUGIN_CONTINUE;
    }

    // agility lvl
    if (item == 4)
    {
        CED_SetCell(turretEntity, CED_TURRET_AGILITY_LEVEL, 4);
        showTurretDetailMenu(id, turretEntity);
    }
    // buy ammo
    if (item == 5)
    {
        @buyAmmoForTurret(turretEntity);
        showTurretDetailMenu(id, turretEntity);
    }
     //  change shot mode
    else if (item == 6)
    {
        @changeTurretShotModeToNext(turretEntity);
        showTurretDetailMenu(id, turretEntity);
    }

    return PLUGIN_CONTINUE;
}

@buyAmmoForTurret(ent)
{
    new turretKey[33];
    getTurretKey(ent, turretKey);

    new reloadAmmo = getTurretReloadAmmo(turretKey);
    new Float:reloadTime = getTurretReloadTime(turretKey);

    CED_SetCell(ent, CED_TURRET_IS_RELOADING, 1);

    new parameters[3];
    parameters[0] = getTurretOwner(ent);
    parameters[1] = ent;
    parameters[2] = reloadAmmo;

    set_task(reloadTime, "@reloadTurret", .parameter = parameters, .len = 3);
}

@reloadTurret(parameters[3])
{
    new ent = parameters[1];
    new ammoToAdd = parameters[2];

    // set information turret reloading ends
    CED_SetCell(ent, CED_TURRET_IS_RELOADING, 0);

    // save new ammount of ammo
    new currentTurretAmmo = getTurretAmmo(ent);
    CED_SetCell(ent, CED_TURRET_AMMO, currentTurretAmmo + ammoToAdd);

    // is turret menu is still opened - refresh it
    refreshTurretDetailMenuIfPlayerStillHaveItOpened(ent);
}

@changeTurretShotModeToNext(ent)
{
    new TURRET_SHOT_MODE:turretShotMode = getTurretShotMode(ent);

    // if it's last shot mode available
    // then let's start from begin
    if (turretShotMode == TURRET_SHOT_MODE:(_:TURRET_SHOT_MODE - 1))
    {
        turretShotMode = NEAREST;
    }
    else
    {
        turretShotMode++;
    }

    // update turret informations
    CED_SetCell(ent, CED_TURRET_SHOT_MODE, turretShotMode);
}

@hidePreviousRangersIfNewMenuIsOpened(id, ent)
{
    new turretEntity = getShowedTurretEntInDetailMenu(id);

    if (ent != turretEntity && is_valid_ent(turretEntity))
    {
        detachRangersFromTurret(turretEntity);
    }
}

@hideTurretRangersIfPlayerIsNotTouchingTurret(id)
{
    new turretEntity = getShowedTurretEntInDetailMenu(id);

    if (getPlayerTouchingTurret(id) == turretEntity)
    {
        return;
    }

    detachRangersFromTurret(turretEntity);
}

@saveInformationAboutOpenedTurretMenu(id, ent)
{
	CED_SetCell(id, CED_PLAYER_SHOWED_MENU_TURRET_KEY, ent);
}

@hideCurrentlyShowedTurretMenu(id)
{
    new menu, newMenu;
    player_menu_info(id, menu, newMenu);

    // if menu is for sure exist
    if (newMenu != -1)
    {
        // destroying menu is invoking callback which is
        // clearing informationa about currently showed turret menu
        menu_destroy(newMenu);
    }
}
