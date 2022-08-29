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

    // hide rangers
    detachRangersFromTurret(turretEntity);

    // set data that user is not moving anymore
    @updateUserIsNotMovingAnymore(id);

    // save turret for user
    @addTurretToUsersTurret(id, turretEntity);

    // set other informations like store turret key, turret level, etc
    @setTurretProperties(turretEntity, turretKey);

    // notify plugin that turret has been created
    @sendTurretCreatedForward(turretEntity, id, turretKey);

    // play plant sound
    emit_sound(turretEntity, CHAN_AUTO, "TDNew/turret_plant.wav", 1.0, ATTN_NORM, 0, PITCH_NORM);

    // stop turret & wait to activate
    new Float:activationTime = getTurretActivationTime(turretKey);

    new parameters[1];
    parameters[0] = turretEntity;

    set_task(activationTime, "@activateTurret", .parameter = parameters, .len = 1);
}

@activateTurret(parameters[1])
{
    // get turret
    new ent = parameters[0];
    new ownerId = getTurretOwner(ent);

    // play sound
    emit_sound(ent, CHAN_AUTO, "TDNew/turret_ready.wav", 1.0, ATTN_NORM, 0, PITCH_NORM);

    // start turret think
    CED_SetCell(ent, CED_TURRET_IS_ENABLED, 1);

    // set next think
    entity_set_float(ent, EV_FL_nextthink, get_gametime() + 0.1);

    // if user is touching his turret, show him menu
    if (getPlayerTouchingTurret(ownerId) == ent)
    {
        showTurretDetailMenu(ownerId, ent);
    }
}

@sendTurretCreatedForward(turretEntity, id, turretKey[33])
{
    // get destination plugin
    new pluginId = getPluginIdByTurretKey(turretKey);

    executeOnTurretCreatedForward(pluginId, turretEntity, id);
}

@setTurretProperties(ent, turretKey[33])
{
    // update class name
    entity_set_string(ent, EV_SZ_classname, TURRET_CLASSNAME);

    // turret is not moving anymore
    CED_SetCell(ent, CED_TURRET_IS_MOVING, 0);

    // set start ammo
    new startAmmo = getTurretStartAmmo(turretKey);
    CED_SetCell(ent, CED_TURRET_AMMO, startAmmo);

    // Make turret disabled - need to be enabled after activation time
    CED_SetCell(ent, CED_TURRET_IS_ENABLED, 0);

    // update turret model
    entity_set_model(ent, "models/TDNew/sentrygun_1.mdl");

    // make turret touchable
    entity_set_int(ent, EV_INT_solid, SOLID_TRIGGER);
    entity_set_size(ent, Float:{-16.0, -16.0, 0.0}, Float:{16.0, 16.0, 48.0});

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