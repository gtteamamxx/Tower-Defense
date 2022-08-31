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

public getPlayerTouchingTurret(id)
{
    new touchedTurretEntByPlayer;
    CED_GetCell(id, CED_PLAYER_TOUCHING_TURRET_ENTITY_KEY, touchedTurretEntByPlayer);

    return touchedTurretEntByPlayer;
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

public getTurretTargetMonster(ent)
{
    new monsterEntity; 
    CED_GetCell(ent, CED_TURRET_TARGET_MONSTER_ENTITY, monsterEntity);

    return monsterEntity;
}

public getTurretAmmo(ent)
{
    new turretAmmo; 
    CED_GetCell(ent, CED_TURRET_AMMO, turretAmmo);

    return turretAmmo;
}

public Float:getTurretActivationTime(turretKey[33])
{
    new Array:turretInfoArray;
    TrieGetCell(g_TurretInfoTrie, turretKey, turretInfoArray);

    new Float:activationTime = Float:ArrayGetCell(turretInfoArray, _:TURRET_ACTIVATION_TIME);
    
    return activationTime;
}

public Float:getTurretUpgradeTime(turretKey[33])
{
    new Array:turretInfoArray;
    TrieGetCell(g_TurretInfoTrie, turretKey, turretInfoArray);

    new Float:activationTime = Float:ArrayGetCell(turretInfoArray, _:TURRET_UPGRADE_TIME);
    
    return activationTime;
}

public bool:isTurretEnabled(ent)
{
    new bool:isTurretEnabled;
    CED_GetCell(ent, CED_TURRET_IS_ENABLED, isTurretEnabled);
    
    return isTurretEnabled;
}

public bool:isTurretReloading(ent)
{
    new bool:isTurretReloading;
    CED_GetCell(ent, CED_TURRET_IS_RELOADING, isTurretReloading);
    
    return isTurretReloading;
}

public Float:getTurretReloadTime(turretKey[33])
{
    new Array:turretInfoArray;
    TrieGetCell(g_TurretInfoTrie, turretKey, turretInfoArray);

    new Float:activationTime = Float:ArrayGetCell(turretInfoArray, _:TURRET_RELOAD_TIME);
    
    return activationTime;
}

public Float:getTurretRangeToShot(ent)
{
    // get current turret range level
    new rangeLevel;
    CED_GetCell(ent, CED_TURRET_RANGE_LEVEL, rangeLevel);

    // get turret key
    new turretKey[33];
    getTurretKey(ent, turretKey);

    new Float:range[2];
    getTurretRangeForLevel(turretKey, rangeLevel, range);

    // return max range
    return range[1];
}

public Float:getTurretDamageForDistance(ent, Float:distance)
{
    // get curren range & damage
    new Float:currentRange[2];
    getCurrentTurretRange(ent, currentRange);

    new Float:currentDamage[2];
    getCurrentTurretDamage(ent, currentDamage);

    // if distance is farthest than max, turret need to miss shot
    if (distance > currentRange[1])
    {
        return 0.0;
    }
    else
    {
        // calculate damage multiplier
        new Float:distanceMultiplier = 1.0;

        if (distance > currentRange[0])
        {
            distanceMultiplier = 1.0 - ((distance - currentRange[0]) / (currentRange[1] - currentRange[0]));
        }

        new Float:damage = random_float(currentDamage[0], currentDamage[1]) * distanceMultiplier;
        return damage;
    }
}


public isFirerateLevelExist(turretKey[33], firerateLevel)
{
    new Array:turretInfoArray;
    TrieGetCell(g_TurretInfoTrie, turretKey, turretInfoArray);
    
    new Array:firerateArray = ArrayGetCell(turretInfoArray, _:TURRET_FIRERATE);
    return firerateLevel <= ArraySize(firerateArray);
}

public getCurrentTurretFirerateLevel(ent)
{
    new firerateLevel;
    CED_GetCell(ent, CED_TURRET_FIRERATE_LEVEL, firerateLevel);

    return firerateLevel;
}

public getCurrentTurretFirerate(ent, Float:firerate[2])
{
    new firerateLevel = getCurrentTurretFirerateLevel(ent);

    new turretKey[33];
    getTurretKey(ent, turretKey);

    getTurretFirerateForLevel(turretKey, firerateLevel, firerate);
}

public getTurretFirerateForLevel(turretKey[33], firerateLevel, Float:firerate[2])
{
    new Array:turretInfoArray;
    TrieGetCell(g_TurretInfoTrie, turretKey, turretInfoArray);

    new Array:firerateArray = ArrayGetCell(turretInfoArray, _:TURRET_FIRERATE);
    ArrayGetArray(firerateArray, firerateLevel - 1, firerate);
}

public getCurrentTurretDamageLevel(ent)
{
    new damageLevel;
    CED_GetCell(ent, CED_TURRET_DAMAGE_LEVEL, damageLevel);

    return damageLevel;
}

public getShotModeName(TURRET_SHOT_MODE:shotMode, szName[33])
{
    switch(shotMode)
    {
        case NEAREST: formatex(szName, 32, "Nearest");
        case FARTHEST: formatex(szName, 32, "Farthest");
        case STRONGEST: formatex(szName, 32, "Strongest");
        case WEAKEST: formatex(szName, 32, "Weakest");
        case FOLLOW: formatex(szName, 32, "Follow");
        default: formatex(szName, 32, "Unknown");
    }
}

getCurrentTurretShotModeName(ent, shotModeName[33])
{
    new TURRET_SHOT_MODE:turretShotMode = getTurretShotMode(ent);
    getShotModeName(turretShotMode, shotModeName);
}

public TURRET_SHOT_MODE:getTurretShotMode(ent)
{
    new TURRET_SHOT_MODE:shotMode;
    CED_GetCell(ent, CED_TURRET_SHOT_MODE, shotMode);

    return shotMode;
}

public getShowedTurretEntInDetailMenu(id)
{
    new ent;
    CED_GetCell(id, CED_PLAYER_SHOWED_MENU_TURRET_KEY, ent);

    return ent;
}

public isDamageLevelExist(turretKey[33], damageLevel)
{
    new Array:turretInfoArray;
    TrieGetCell(g_TurretInfoTrie, turretKey, turretInfoArray);
    
    new Array:damageArray = ArrayGetCell(turretInfoArray, _:TURRET_DAMAGE);
    return damageLevel <= ArraySize(damageArray) ;
}

public getCurrentTurretDamage(ent, Float:damage[2])
{
    new damageLevel = getCurrentTurretDamageLevel(ent);

    new turretKey[33];
    getTurretKey(ent, turretKey);

    getTurretDamageForLevel(turretKey, damageLevel, damage);
}

public getTurretDamageForLevel(turretKey[33], damageLevel, Float:damage[2])
{
    new Array:turretInfoArray;
    TrieGetCell(g_TurretInfoTrie, turretKey, turretInfoArray);

    new Array:damageArray = ArrayGetCell(turretInfoArray, _:TURRET_DAMAGE);
    ArrayGetArray(damageArray, damageLevel - 1, damage);
}

public isRangeLevelExist(turretKey[33], rangeLevel)
{
    new Array:turretInfoArray;
    TrieGetCell(g_TurretInfoTrie, turretKey, turretInfoArray);
    
    new Array:rangeArray = ArrayGetCell(turretInfoArray, _:TURRET_RANGE);
    return rangeLevel <= ArraySize(rangeArray) ;
}

public getCurrentTurretRangeLevel(ent)
{
    new rangeLevel;
    CED_GetCell(ent, CED_TURRET_RANGE_LEVEL, rangeLevel);

    return rangeLevel;
}

public getCurrentTurretRange(ent, Float:range[2])
{
    // get current turret range level
    new rangeLevel = getCurrentTurretRangeLevel(ent);

    // get turret key
    new turretKey[33];
    getTurretKey(ent, turretKey);

    new Float:accuracy[2];
    getCurrentTurretAccuracy(ent, accuracy);

    // get accuracy for first level
    new Float:accuracyForFirstLevel[2];
    getTurretAccuracyForLevel(turretKey, 1, accuracyForFirstLevel);

    // get current turret range by level
    getTurretRangeForLevel(turretKey, rangeLevel, range);

    // add additional range by turret accuracy
    new Float:scale = ((accuracy[0] * accuracyForFirstLevel[0]) / accuracyForFirstLevel[0]) - accuracyForFirstLevel[0];

    new Float:additionalRange = range[0] * scale;
    range[0] += additionalRange;
}

public getTurretRangeForLevel(turretKey[33], rangeLevel, Float:range[2])
{
    new Array:turretInfoArray;
    TrieGetCell(g_TurretInfoTrie, turretKey, turretInfoArray);

    new Array:rangeArray = ArrayGetCell(turretInfoArray, _:TURRET_RANGE);
    ArrayGetArray(rangeArray, rangeLevel - 1, range);
}

public isAccuracyLevelExist(turretKey[33], accuracyLevel)
{
    new Array:turretInfoArray;
    TrieGetCell(g_TurretInfoTrie, turretKey, turretInfoArray);
    
    new Array:accuracyArray = ArrayGetCell(turretInfoArray, _:TURRET_ACCURACY);
    return accuracyLevel <= ArraySize(accuracyArray) ;
}

public isAgilityLevelExist(turretKey[33], agilityLevel)
{
    new Array:turretInfoArray;
    TrieGetCell(g_TurretInfoTrie, turretKey, turretInfoArray);
    
    new Array:agilityArray = ArrayGetCell(turretInfoArray, _:TURRET_AGILITY);
    return agilityLevel <= ArraySize(agilityArray) ;
}

public getCurrentTurretAccuracyLevel(ent)
{
    new accuracyLevel;
    CED_GetCell(ent, CED_TURRET_ACCURACY_LEVEL, accuracyLevel);

    return accuracyLevel;
}

public getCurrentTurretAgilityLevel(ent)
{
    new agilityLevel;
    CED_GetCell(ent, CED_TURRET_AGILITY_LEVEL, agilityLevel);

    return agilityLevel;
}

public getCurrentTurretAccuracy(ent, Float:accuracy[2])
{
    // get current turret accuracy level
    new accuracyLevel = getCurrentTurretAccuracyLevel(ent);

    // get turret key
    new turretKey[33];
    getTurretKey(ent, turretKey);

    getTurretAccuracyForLevel(turretKey, accuracyLevel, accuracy);
}

public getCurrentTurretAgility(ent, Float:agility[2])
{
    // get current turret agility level
    new agilityLevel = getCurrentTurretAgilityLevel(ent);

    // get turret key
    new turretKey[33];
    getTurretKey(ent, turretKey);

    getTurretAgilityForLevel(turretKey, agilityLevel, agility);
}

public getTurretAccuracyForLevel(turretKey[33], accuracyLevel, Float:accuracy[2])
{
    new Array:turretInfoArray;
    TrieGetCell(g_TurretInfoTrie, turretKey, turretInfoArray);

    new Array:accuracyArray = ArrayGetCell(turretInfoArray, _:TURRET_ACCURACY);
    ArrayGetArray(accuracyArray, accuracyLevel - 1, accuracy);
}

public getTurretAgilityForLevel(turretKey[33], agilityLevel, Float:agility[2])
{
    new Array:turretInfoArray;
    TrieGetCell(g_TurretInfoTrie, turretKey, turretInfoArray);

    new Array:agilityArray = ArrayGetCell(turretInfoArray, _:TURRET_AGILITY);
    ArrayGetArray(agilityArray, agilityLevel - 1, agility);
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

public getTurretKey(ent, turretKey[33])
{
    CED_GetString(ent, CED_TURRET_KEY, turretKey, 32);
}

public bool:isLowAmmoOnTurret(ent)
{
    new turretAmmo = getTurretAmmo(ent);
    
    // if turret ammo is lower than low ammo limit
    return turretAmmo <= getTurretLowAmmoLevel(ent);
}

public getTurretLowAmmoLevel(ent)
{
    // TODO: Konfiguracja
    return 45;
}

public bool:isTurretEmpty(ent)
{
    new turretAmmo = getTurretAmmo(ent);
    return turretAmmo <= 0;
}

public getTurretStartAmmo(turretKey[33])
{
    new Array:turretInfoArray;
    TrieGetCell(g_TurretInfoTrie, turretKey, turretInfoArray);

    new Float:ammo = ArrayGetCell(turretInfoArray, _:TURRET_START_AMMO);
    return floatround(ammo);
}

public getTurretReloadAmmo(turretKey[33])
{
    new Array:turretInfoArray;
    TrieGetCell(g_TurretInfoTrie, turretKey, turretInfoArray);

    new Float:reloadAmmo = ArrayGetCell(turretInfoArray, _:TURRET_RELOAD_AMMO);
    return floatround(reloadAmmo);
}

public getMaxNumberOfTurrets(turretKey[33])
{
    new Array:turretInfoArray;
    TrieGetCell(g_TurretInfoTrie, turretKey, turretInfoArray);

    new numberOfTurrets = floatround(ArrayGetCell(turretInfoArray, _:TURRET_MAX_COUNT));
    return numberOfTurrets;
}

stock turnTurretToMonster(ent, any:monster, bool:turnBarrel = false)
{
    new Float:monsterOrigin[3];
    entity_get_vector(monster, EV_VEC_origin, monsterOrigin);

    turnTurretToOrigin(ent, monsterOrigin, turnBarrel);
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
