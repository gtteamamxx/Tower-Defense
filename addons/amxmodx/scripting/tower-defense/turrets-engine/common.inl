#if defined _towerdefense_turrets_common_included
  #endinput
#endif
#define _towerdefense_turrets_common_included

public getNumberOfLoadedTurrets()
{
    return TrieGetSize(g_TurretInfoTrie);
}

public getNumberOfRegisteredTurrets()
{
    return TrieGetSize(g_RegisteredTurretsTrie);
}

public bool:isConfigurationExistForTurret(turretKey[33])
{
    return bool:TrieKeyExists(g_TurretInfoTrie, turretKey);
}

public Array:getPlayersTurretArray(id)
{
    new Array:playersTurretArray;
    CED_GetCell(id, CED_PLAYER_TURRETS_ARRAY_KEY, playersTurretArray);

    return playersTurretArray; 
}

public bool:isTurretMoving(ent)
{
    new isTurretMoving;
    CED_GetCell(ent, CED_TURRET_IS_MOVING, isTurretMoving);

    return isTurretMoving == 1;
}

public isTurretOfKey(ent, turretKey[33])
{
    new realTurretKey[33];
    getTurretKey(ent, realTurretKey);

    new bool:isTurretOfKey = bool:equali(realTurretKey, turretKey);
    return isTurretOfKey;
}

public getNumberOfTurretsOnServer(turretKeyToFind[33])
{
    new numberOfTurrets = 0;

    //get maximum number of players
    new numberOfPlayers = get_maxplayers();

    // loop through all players which may be connected
    for(new i = 1; i <= numberOfPlayers; ++i)
    {
        if (!is_user_connected(i)) continue;

        // get player turrets array
        new Array:playerTurretsArray = getPlayersTurretArray(i);

        // if player doesn't have any turret skip
        if (playerTurretsArray == Invalid_Array) continue;

        // loop through all player turrets
        new numberOfPlayerTurrets = ArraySize(playerTurretsArray);
        for(new j = 0; j < numberOfPlayerTurrets; ++j)
        {
            new ent = ArrayGetCell(playerTurretsArray, j);

            // if it's turret we want then add number fo turrets
            if (isTurretOfKey(ent, turretKeyToFind))
            {
                numberOfTurrets++;
            }
        }
    }

    return numberOfTurrets;
}

public getPluginIdByTurretKey(turretKey[33])
{
    new Array:turretInfoArray;
    TrieGetCell(g_RegisteredTurretsTrie, turretKey, turretInfoArray);

    return ArrayGetCell(turretInfoArray, _:TURRET_PLUGIN_ID);
}

public getTurretOwner(ent)
{
    new ownerId;
    CED_GetCell(ent, CED_TURRET_OWNER_KEY, ownerId);

    return ownerId;
}

public getTurretName(turretKey[33], turretName[33])
{
    new Array:turretInfoArray;
    TrieGetCell(g_RegisteredTurretsTrie, turretKey, turretInfoArray);

    ArrayGetString(turretInfoArray, _:TURRET_NAME, turretName, 32);
}

public Float:getTurretActivationTime(turretKey[33])
{
    new Array:turretInfoArray;
    TrieGetCell(g_TurretInfoTrie, turretKey, turretInfoArray);

    new Float:activationTime = Float:ArrayGetCell(turretInfoArray, _:TURRET_ACTIVATION_TIME);
    
    return activationTime;
}

public getTurretRangeForLevel(turretKey[33], rangeLevel, Float:range[2])
{
    new Array:turretInfoArray;
    TrieGetCell(g_TurretInfoTrie, turretKey, turretInfoArray);

    new Array:rangeArray = ArrayGetCell(turretInfoArray, _:TURRET_RANGE);

    ArrayGetArray(rangeArray, rangeLevel - 1, range);
}

public isTurret(ent)
{
    new blank;
    new isKeyExists = CED_GetCell(ent, CED_TURRET_OWNER_KEY, blank);
    return isKeyExists;
}

public isRanger(ent)
{
    new blank;
    new isKeyExists = CED_GetCell(ent, CED_RANGER_TURRET_ENTITY_KEY, blank);
    return isKeyExists;
}

public Float:getTurretRange(turretKey[33])
{
    new Array:turretInfoArray;
    TrieGetCell(g_TurretInfoTrie, turretKey, turretInfoArray);

    new Float:activationTime = Float:ArrayGetCell(turretInfoArray, _:TURRET_ACTIVATION_TIME);
    
    return activationTime;
}

public getTurretKey(ent, turretKey[33])
{
    CED_GetString(ent, CED_TURRET_KEY, turretKey, 32);
}

public getTurretStartAmmo(turretKey[33])
{
    new Array:turretInfoArray;
    TrieGetCell(g_TurretInfoTrie, turretKey, turretInfoArray);

    new ammo = ArrayGetCell(turretInfoArray, _:TURRET_START_AMMO);
    return ammo;
}

public getMaxNumberOfTurrets(turretKey[33])
{
    new Array:turretInfoArray;
    TrieGetCell(g_TurretInfoTrie, turretKey, turretInfoArray);

    new numberOfTurrets = floatround(ArrayGetCell(turretInfoArray, _:TURRET_MAX_COUNT));
    return numberOfTurrets;
}

stock turnTurretToOrigin(ent, Float:enemyOrigin[3] = {0.0, 0.0, 0.0}, bool:turnBarrel = false)
{
    new Float:sentryOrigin[3];
    entity_get_vector(ent, EV_VEC_origin, sentryOrigin)

    new newTrip, Float:newAngle = floatatan(((enemyOrigin[1]-sentryOrigin[1])/(enemyOrigin[0]-sentryOrigin[0])), radian) * 57.2957795;

    if(enemyOrigin[0] < sentryOrigin[0])
        newAngle += 180.0;
    if(newAngle < 0.0)
        newAngle += 360.0;

    sentryOrigin[2] += 35.0
    if(enemyOrigin[2] > sentryOrigin[2])
        newTrip = 0;
    if(enemyOrigin[2] < sentryOrigin[2])
        newTrip = 255;
    if(enemyOrigin[2] == sentryOrigin[2])
        newTrip = 127;
        
    entity_set_byte(ent, EV_BYTE_controller1, floatround(newAngle*0.70833));
    entity_set_byte(ent, EV_BYTE_controller2, newTrip);

    if(turnBarrel)
        entity_set_byte(ent, EV_BYTE_controller3, entity_get_byte(ent, EV_BYTE_controller3)+20>255? 0: entity_get_byte(ent, EV_BYTE_controller3)+20);
}

stock getOriginByDistFromPlayer(id, Float:dist, Float:origin[3]) 
{
    new Float:playerOrigin[3];
    entity_get_vector(id, EV_VEC_origin, playerOrigin);

    if(dist == 0) 
    {
        origin = playerOrigin;
        return;
    }

    new Float:angle[3];
    entity_get_vector(id, EV_VEC_v_angle, angle);
    angle[0] *= -1;

    origin[0] = playerOrigin[0] + dist * floatcos(angle[1], degrees) * (floatabs(floatcos(angle[0], degrees)));
    origin[1] = playerOrigin[1] + dist * floatsin(angle[1], degrees) * (floatabs(floatcos(angle[0], degrees)));
    origin[2] = playerOrigin[2];
}
