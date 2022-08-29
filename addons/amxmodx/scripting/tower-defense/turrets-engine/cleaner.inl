#if defined _towerdefense_cleaner_included
  #endinput
#endif
#define _towerdefense_cleaner_included

public freeResourcesOnPluginEnd()
{
    // free turret info trie
    @freeTurretInfoTrie();

    // free registration info
    @freeTurretRegistrationTrie();
}

public removeAllPlayerTurrets(id)
{
    // get player turrets
    new Array:playerTurretsArray = getPlayersTurretArray(id);
    
    // if player had turrets
    if (playerTurretsArray != Invalid_Array) 
    {
        new playerTurretsNumber = ArraySize(playerTurretsArray);
        
        // loop through all player turrets
        for(new i = 0; i < playerTurretsNumber; ++i) 
        {
            new turretEntity = ArrayGetCell(playerTurretsArray, i);
            
            // remove turret
            removeTurretEntity(turretEntity);            
        }
    }

    // free array handle and update players info
    ArrayDestroy(playerTurretsArray);

    CED_SetCell(id, CED_PLAYER_TURRETS_ARRAY_KEY, Invalid_Array);

    CED_SetCell(id, CED_PLAYER_SHOWED_MENU_TURRET_KEY, -1);

    // remove additionaly player's moving turret if there's one
    removeMovingTurretForPlayer(id);
}

public removeTurretEntity(ent)
{
    if (!is_valid_ent(ent))
    {
        return;
    }

    // remove turret rangers if exists
    detachRangersFromTurret(ent);

    // remove turret
    remove_entity(ent);
}

public removeMovingTurretForPlayer(id)
{
    // get moving turret
    new turretEntity;
    CED_GetCell(id, CED_PLAYER_MOVING_TURRET_ENTITY_KEY, turretEntity);

    // remove turret
    removeTurretEntity(turretEntity);

    // set player entity moving entity as null
    CED_SetCell(id, CED_PLAYER_MOVING_TURRET_ENTITY_KEY, 0);
}

@freeTurretRegistrationTrie()
{
     // create iterator for all keys in trie
    new TrieIter:iter = TrieIterCreate(g_RegisteredTurretsTrie);

    // loop through all keys in trie
    while(!TrieIterEnded(iter))
    {
        // get turret info array
        new Array:turretInfoArray;
        TrieIterGetCell(iter, Array:turretInfoArray);

        // free array
        ArrayDestroy(turretInfoArray);

        // go to next item
        TrieIterNext(iter);
    }

    // free iter & trie
    TrieIterDestroy(iter);

    TrieDestroy(g_RegisteredTurretsTrie);
}

@freeTurretInfoTrie()
{
    // create iterator for all keys in trie
    new TrieIter:iter = TrieIterCreate(g_TurretInfoTrie);

    // loop through all keys in trie
    while(!TrieIterEnded(iter))
    {
        // get turret info array
        new Array:turretInfoArray;
        TrieIterGetCell(iter, Array:turretInfoArray);

        // loop through all items in array which are
        // exactly turret info
        for(new TURRET_INFO:i; _:i < ArraySize(turretInfoArray); i = TURRET_INFO:(_:i + 1)) 
        {
            // get item which is an array of levels
            new Array:turretInfoDetails = ArrayGetCell(turretInfoArray, _:i);

            // free turret details array
            // note: we don't have to be sure that turretInfoDetails is 
            // exactly an array because
            // ArrayDestroy returns 1 on success and 0 on failure 
            // no errors are thrown
            ArrayDestroy(turretInfoDetails);
        }

        // free turret info array
        ArrayDestroy(turretInfoArray);

        // find next key
        TrieIterNext(iter);
    }

    // free iter & trie
    TrieIterDestroy(iter);

    TrieDestroy(g_TurretInfoTrie);
}
