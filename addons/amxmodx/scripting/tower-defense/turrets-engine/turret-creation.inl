#if defined _towerdefense_turrets_player_turret_creation_included
  #endinput
#endif
#define _towerdefense_turrets_player_turret_creation_included

public createTurretForPlayer(id, turretKey[33])
{
    // if player died we don't want to do anything
    if (!is_user_alive(id))
    {
        return;
    }

    // get moving turret
    new turretEntity;
    CED_GetCell(id, CED_PLAYER_MOVING_TURRET_ENTITY_KEY, turretEntity);

    // set data that user is not moving anymore
    @updateUserIsNotMovingAnymore(id);

    // save turret for user
    @addTurretToUsersTurret(id, turretEntity);

    // set other informations like store turret key, turret level, etc
    @setTurretProperties(turretEntity, turretKey);

    // activate turret
    @activateTurret(turretEntity, id, turretKey);
}

@activateTurret(turretEntity, id, turretKey[33])
{
    // get destination plugin
    new pluginId = getPluginIdByTurretKey(turretKey);

    executeOnTurretCreatedForward(pluginId, turretEntity, id);
}

@setTurretProperties(ent, turretKey[33])
{
    // set basic properties
    CED_SetCell(ent, CED_TURRET_LEVEL, 1);
    CED_SetString(ent, CED_TURRET_KEY, turretKey);

    // update turret model
    entity_set_model(ent, "models/TDNew/sentrygun_1.mdl");

    // update class name
    entity_set_string(ent, EV_SZ_classname, TURRET_CLASSNAME);

    // make turret touchable
    entity_set_int(ent, EV_INT_solid, SOLID_TRIGGER)

    // remove fade effect
    fm_set_rendering(ent, kRenderFxNone, 0, 0, 0, kRenderNormal, 0);
}

@addTurretToUsersTurret(id, turretEntity)
{
    // get player turrets array
    new Array:playerTurretsArray = getPlayersTurretArray(id);

    // if player does not have any turrets
    // create player turrets array
    if (playerTurretsArray == Invalid_Array) 
    {
        playerTurretsArray = ArrayCreate();
        CED_SetCell(id, CED_PLAYER_TURRETS_ARRAY_KEY, playerTurretsArray);
    }

    // add turret for player
    ArrayPushCell(playerTurretsArray, turretEntity);
}

@updateUserIsNotMovingAnymore(id)
{
    CED_SetCell(id, CED_PLAYER_MOVING_TURRET_ENTITY_KEY, 0);
}