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

public getPluginIdByTurretKey(turretKey[33])
{
    new Array:turretInfoArray;
    TrieGetCell(g_RegisteredTurretsTrie, turretKey, turretInfoArray);

    return ArrayGetCell(turretInfoArray, _:TURRET_PLUGIN_ID);
}

public getTurretName(turretKey[33], turretName[33])
{
    new Array:turretInfoArray;
    TrieGetCell(g_RegisteredTurretsTrie, turretKey, turretInfoArray);

    ArrayGetString(turretInfoArray, _:TURRET_NAME, turretName, 32);
}

public getMaxNumberOfTurrets(turretKey[33])
{
    new Array:turretInfoArray;
    TrieGetCell(g_TurretInfoTrie, turretKey, turretInfoArray);

    new numberOfTurrets = ArrayGetCell(turretInfoArray, _:TURRET_MAX_COUNT);

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
    origin[2] = playerOrigin[2]
}
