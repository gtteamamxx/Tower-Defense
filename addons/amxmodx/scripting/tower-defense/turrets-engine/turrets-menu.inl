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

    // create iterator for all turrets
    new TrieIter:iter = TrieIterCreate(g_RegisteredTurretsTrie);

    // loop through all keys in trie
    new turretName[33], turretKey[33];
    while(!TrieIterEnded(iter))
    {
        // get turret info array
        new Array:turretInfoArray;
        TrieIterGetCell(iter, Array:turretInfoArray);

        // get turret name
        ArrayGetString(turretInfoArray, _:TURRET_NAME, turretName, 32);

        // get turret key
        ArrayGetString(turretInfoArray, _:TURRET_KEY, turretKey, 32);

        // add item with turret key info
        menu_additem(menu, turretName, .info = turretKey);

        // go to next turret
        TrieIterNext(iter);
    }

    // free iter
    TrieIterDestroy(iter);

    // display menu for player
    menu_display(id, menu);
}

@onPlayerTurretSelected(id, menu, item)
{
    // if player somehow died
    if (!is_user_alive(id))
    {
        return;
    }

    new selectedTurretKey[33], name[3];
    new access, cb;

    // get selected turret key
    menu_item_getinfo(menu, item, access, selectedTurretKey, 32, name, 2, cb)

    // free menu handler
    menu_destroy(menu);

    // start creating turret for player
    startCreatingTurretForPlayer(id, selectedTurretKey);
}
