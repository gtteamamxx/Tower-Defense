#if defined _towerdefense_turrets_menu_included
  #endinput
#endif
#define _towerdefense_turrets_menu_included

public openTurretsMenu(id)
{
    // if no turrets then do nothing
    if (!g_AreTurretsAvailable) 
    {
        client_print(id, print_chat, "Turrets are not available at this map.");
        return;
    }

    // create menu
    new menu = menu_create("Select turret to create:", "@onPlayerTurretSelected");
    new visibilityCb = menu_makecallback("@turretsMenuItemVisibility");

    // create iterator for all turrets
    new TrieIter:iter = TrieIterCreate(g_RegisteredTurretsTrie);

    // loop through all keys in trie
    static turretName[64], turretKey[33];
    while(!TrieIterEnded(iter))
    {
        // get turret info array
        new Array:turretInfoArray;
        TrieIterGetCell(iter, Array:turretInfoArray);

        // get turret name
        ArrayGetString(turretInfoArray, _:TURRET_NAME, turretName, 32);

        // get turret key
        ArrayGetString(turretInfoArray, _:TURRET_KEY, turretKey, 32);

        // if we reached limit change menu item text

        if (@isTurretLimitReached(turretKey))
        {
            format(turretName, 63, "%s [MAX LIMIT REACHED]", turretName);
        }
        else
        {
            format(turretName, 63, "%s [ \y%d / \r%d \w]", turretName, getNumberOfTurretsOnServer(turretKey), getMaxNumberOfTurrets(turretKey));
        }

        // add item with turret key info
        menu_additem(menu, turretName, .info = turretKey, .callback = visibilityCb);

        // go to next turret
        TrieIterNext(iter);
    }

    // free iter
    TrieIterDestroy(iter);

    // display menu for player
    menu_display(id, menu);
}

@turretsMenuItemVisibility(id, menu, item)
{
    // if it's exit menu
    if (item == MENU_EXIT)
    {
        return ITEM_IGNORE;
    }

    new selectedTurretKey[33], name[3];
    new access, cb;

    // get selected turret key
    menu_item_getinfo(menu, item, access, selectedTurretKey, 32, name, 2, cb)

    // if turret limit is reached then disable item
    if (@isTurretLimitReached(selectedTurretKey))
    {
        return ITEM_DISABLED;
    }

    // let item be enabled
    return ITEM_IGNORE;
}

@onPlayerTurretSelected(id, menu, item)
{
    // if player somehow died or escaped
    if (!is_user_alive(id) || item == MENU_EXIT)
    {
        return;
    }

    new selectedTurretKey[33], name[3];
    new access, cb;

    // get selected turret key
    menu_item_getinfo(menu, item, access, selectedTurretKey, 32, name, 2, cb)

    // free menu handler
    menu_destroy(menu);

    // if turret limit is reached we can't create new turret
    // so open again player menu to show new action
    if (@isTurretLimitReached(selectedTurretKey))
    {
        client_print(id, print_chat, "Maximum number of this turret is reached!");
        openTurretsMenu(id);
    }
    // start creating turret for player
    else
    {
        startCreatingTurretForPlayer(id, selectedTurretKey);
    }
}


bool:@isTurretLimitReached(turretKey[33])
{
    // get number of turrets on server
    new turretsNumber = getNumberOfTurretsOnServer(turretKey);

    // get maximum number of turrets 
    new maxTurretsNumber = getMaxNumberOfTurrets(turretKey);

    // we can create turret only of actual number is less than maximum
    return turretsNumber >= maxTurretsNumber;
}