#if defined _towerdefense_turrets_turret_move_manager
  #endinput
#endif
#define _towerdefense_turrets_turret_move_manager

public registerEventsForTurretMoving()
{
    register_think(TURRET_MOVE_CLASSNAME, "@refreshTurretMovingPosition");
}

public createTurretForCreationForPlayer(id, turretKey[33])
{
    // if player is not alive we can't do it
    if (!is_user_alive(id)) 
    {
        return;
    }

    @createTurretEntityForMoving(turretKey, .ownerId = id);
}

@refreshTurretMovingPosition(ent)
{
    // get owner id
    new ownerId = getTurretOwner(ent);

    // get new position and set it
    new Float:ownerOrigin[3];
    getOriginByDistFromPlayer(ownerId, DIST_MOVING, ownerOrigin)

    entity_set_vector(ent, EV_VEC_origin, ownerOrigin);

    // make entity touch ground
    drop_to_floor(ent);

    // animate turret at pointing direction
    new ownerPointingDirection[3]; 
    get_user_origin(ownerId, ownerPointingDirection, 3);
    IVecFVec(ownerPointingDirection, ownerOrigin);

    turnTurretToOrigin(ent, .enemyOrigin = ownerOrigin);
    
    // calculate if turret can be placed here
    @calculateIfEntityCanBePlacedAtCurrentPosition(ent);

    // update model
    @updateTurretModelByPosibilityOfPlacing(ent);

    // start next think if turret is still moving
    entity_set_float(ent, EV_FL_nextthink, get_gametime() +  0.05);
}

@createTurretEntityForMoving(turretKey[33], ownerId)
{
    // create entity
    new ent = cs_create_entity("info_target");

    // set basic properties
    @setMovingPropertiesToEntity(ownerId, ent, turretKey);

    // attach ranger
    createAndAttachRangerToTurret(ent);
}

@setMovingPropertiesToEntity(ownerId, ent, turretKey[33])
{
    // get start position
    new Float:ownerOrigin[3];
    getOriginByDistFromPlayer(ownerId, DIST_MOVING, ownerOrigin)

    // set required properties
    entity_set_string(ent, EV_SZ_classname, TURRET_MOVE_CLASSNAME);
    entity_set_vector(ent, EV_VEC_origin, ownerOrigin);
    entity_set_size(ent, Float:{-16.0, -16.0, 0.0}, Float:{16.0, 16.0, 48.0});
    entity_set_int(ent, EV_INT_solid, SOLID_NOT);
    CED_SetString(ent, CED_TURRET_KEY, turretKey);

    // set turret is moving
    CED_SetCell(ent, CED_TURRET_IS_MOVING, 1);

    // set owner
    CED_SetCell(ent, CED_TURRET_OWNER_KEY, ownerId);
    
    // set basic properties
    CED_SetCell(ent, CED_SKILL_ACCURACY_LEVEL, 1);
    CED_SetCell(ent, CED_SKILL_FIRERATE_LEVEL, 1);
    CED_SetCell(ent, CED_SKILL_DAMAGE_LEVEL, 1);
    CED_SetCell(ent, CED_SKILL_RANGE_LEVEL, 1);
    CED_SetCell(ent, CED_SKILL_AGILITY_LEVEL, 1);
    CED_SetCell(ent, CED_TURRET_SHOT_MODE, SHOT_MODE_NEAREST);

    // assign moving entity to player
    CED_SetCell(ownerId, CED_PLAYER_MOVING_TURRET_ENTITY_KEY, ent);

    // make entity fading
    fm_set_rendering(ent, kRenderFxNone, 0, 0, 0, kRenderTransAdd, 255);

    // start think
    entity_set_float(ent, EV_FL_nextthink, get_gametime() +  0.05);
}

@calculateIfEntityCanBePlacedAtCurrentPosition(ent)
{
    // get owner id
    new ownerId = getTurretOwner(ent);

    new entlist[3];
    new bool:canBePlacedHere = true;

    // if player don't see turret
    if (!fm_is_ent_visible(ownerId, ent)) canBePlacedHere = false;
    
    // or player is placing turret near other one
    else if (find_sphere_class(ent, TURRET_CLASSNAME, 60.0, entlist, 2)) canBePlacedHere = false;

    // or it's forbidden area
    else if (find_sphere_class(ent, "func_illusionary", 10.0, entlist, 2)) canBePlacedHere = false;
    
    // update turret data
    CED_SetCell(ent, CED_ENTITY_PLACE_POSIBILITY_KEY, _:canBePlacedHere);
}

@updateTurretModelByPosibilityOfPlacing(ent)
{
    new bool:canBePlacedAtCurrentPosition;
    CED_GetCell(ent, CED_ENTITY_PLACE_POSIBILITY_KEY, canBePlacedAtCurrentPosition);

    if (canBePlacedAtCurrentPosition)
    {
        entity_set_model(ent, "models/TDNew/sentrygun_2.mdl");
    }
    else
    {
        entity_set_model(ent, "models/TDNew/sentrygun_4.mdl");
    }
}