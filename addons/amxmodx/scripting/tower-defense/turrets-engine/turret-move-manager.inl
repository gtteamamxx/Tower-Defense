#if defined _towerdefense_turrets_turret_move_manager
  #endinput
#endif
#define _towerdefense_turrets_turret_move_manager

public registerEventsForTurretMoving()
{
    register_think(TURRET_MOVE_CLASSNAME, "@refreshTurretMovingPosition");
}

public createTurretForCreationForPlayer(id)
{
    // if player is not alive we can't do it
    if (!is_user_alive(id)) 
    {
        return;
    }

    @createTurretEntityForMoving(.ownerId = id);
}

@refreshTurretMovingPosition(ent)
{
    // get owner id
    new ownerId;
    CED_GetCell(ent, CED_TURRET_OWNER_KEY, ownerId);

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

    // start next think
    entity_set_float(ent, EV_FL_nextthink, get_gametime() +  0.051);
}

@createTurretEntityForMoving(ownerId)
{
    // create entity
    new ent = cs_create_entity("info_target");

    @setMovingPropertiesToEntity(ownerId, ent);
}

@setMovingPropertiesToEntity(ownerId, ent)
{
    // get start position
    new Float:ownerOrigin[3];
    getOriginByDistFromPlayer(ownerId, DIST_MOVING, ownerOrigin)

    // set required properties
    entity_set_vector(ent, EV_VEC_origin, ownerOrigin);
    entity_set_int(ent, EV_INT_solid, SOLID_NOT);
    entity_set_string(ent, EV_SZ_classname, TURRET_MOVE_CLASSNAME);

    // set owner
    CED_SetCell(ent, CED_TURRET_OWNER_KEY, ownerId);
    
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
    new ownerId;
    CED_GetCell(ent, CED_TURRET_OWNER_KEY, ownerId);

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