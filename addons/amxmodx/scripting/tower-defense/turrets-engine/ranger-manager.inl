#if defined _towerdefense_turrets_ranger_manager_included
  #endinput
#endif
#define _towerdefense_turrets_ranger_manager_included

public registerEventsForManageRangerVisibility()
{
    register_forward(FM_AddToFullPack, "@manageRangerVisibility");

    register_touch(TURRET_CLASSNAME, "player", "@showRangerWhenPlayerIsTouchingTurret");
    register_think(RANGER_CLASSNAME, "@hideRangerWhenPlayerIsNotTouchingTurret");
}


public registerEventsForManageRangerPosition()
{
    // update ranger position when player's moving turret
    register_think(RANGER_CLASSNAME, "@refreshRangerPositionWhenTurretIsMoving");
}

public detachRangersFromTurret(ent)
{
    // get rangers of turret
    new minRangerEnt, maxRangerEnt;
    CED_GetCell(ent, CED_TURRET_RANGER_MIN_ENTITY_KEY, minRangerEnt);
    CED_GetCell(ent, CED_TURRET_RANGER_MAX_ENTITY_KEY, maxRangerEnt);

    // remove rangers 
    if (is_valid_ent(minRangerEnt))
    {
        remove_entity(minRangerEnt);
    }

    if (is_valid_ent(maxRangerEnt))
    {
        remove_entity(maxRangerEnt);
    }
}

public createAndAttachRangerToTurret(ent)
{
    // if somehow entity is not valid then do nothing
    if (!is_valid_ent(ent))
    {
        return;
    }
    
    // get turret key
    new turretKey[33];
    getTurretKey(ent, turretKey);

    // get turret range level
    new rangeLevel = @getTurretRangeLevel(ent);

    // get min and max of turrets range
    new Float:minMaxRange[2];
    getTurretRangeForLevel(turretKey, rangeLevel, minMaxRange);

    // create rangers for turret
    new minRangerEnt = @createRangerEnt(ent, minMaxRange[0], .r = 0, .g = 255, .b = 0);
    new maxRangerEnt = @createRangerEnt(ent, minMaxRange[1], .r = 255, .g = 0, .b = 0);

    // save entity informations to turret
    CED_SetCell(ent, CED_TURRET_RANGER_MIN_ENTITY_KEY, minRangerEnt);
    CED_SetCell(ent, CED_TURRET_RANGER_MAX_ENTITY_KEY, maxRangerEnt);
}

@hideRangerWhenPlayerIsNotTouchingTurret(ent)
{
    // get turret
    new turretEntity;
    CED_GetCell(ent, CED_RANGER_TURRET_ENTITY_KEY, turretEntity);

    // if turret is moving don't do anything
    if (isTurretMoving(turretEntity))
    {
        return;
    }

    // get player id
    new id = getTurretOwner(turretEntity);

    // if player is not touching turret anymore
    // or he's touching another turret then remove ranger
    new entlist[2]
    if (!find_sphere_class(id, TURRET_CLASSNAME, 1.0, entlist, 1) || entlist[0] != turretEntity)
    {
        detachRangersFromTurret(turretEntity);
        return;
    }

    // delay next check
    entity_set_float(ent, EV_FL_nextthink, get_gametime() + 0.5);
}

@showRangerWhenPlayerIsTouchingTurret(ent, id)
{
    // get turret owner
    new ownerId = getTurretOwner(ent);

    // if touching player is not owner then don't anyting
    if (id != ownerId) 
    {
        return;
    }

    // get current rangers for turret
    new minRangerEnt, maxRangerEnt;
    CED_GetCell(ent, CED_TURRET_RANGER_MIN_ENTITY_KEY, minRangerEnt);
    CED_GetCell(ent, CED_TURRET_RANGER_MAX_ENTITY_KEY, maxRangerEnt);

    // if turret currently has rangers don't do anything
    if (is_valid_ent(minRangerEnt) && is_valid_ent(maxRangerEnt)) 
    {
        return;
    }

    // create ranger for turret
    createAndAttachRangerToTurret(ent);

    // start checking ranger visibility
    entity_set_float(ent, EV_FL_nextthink, get_gametime() + 0.5);
}

@manageRangerVisibility(es_handle, e, ENT, HOST, hostflags, player, set)
{
    // if player is not connected or target is not turret then don't do anything
    if(!is_user_connected(HOST) || !is_valid_ent(ENT) || !isRanger(ENT))
    {
        return FMRES_IGNORED;
    }
    
    // get player id who we want to see ranger
    new ownerId;
    CED_GetCell(ENT, CED_RANGER_OWNER_KEY, ownerId);
    
    // if it's not owner hide ranger for him
    if (ownerId != HOST) 
    {
        set_es(es_handle, ES_RenderMode, kRenderTransAdd); 
        set_es(es_handle, ES_RenderAmt, 0);  
        return FMRES_OVERRIDE
    }

    return FMRES_IGNORED;
}

@refreshRangerPositionWhenTurretIsMoving(ent)
{
    if (!is_valid_ent(ent))
    {
        return;
    }
    
    // get turret
    new turretEntity;
    CED_GetCell(ent, CED_RANGER_TURRET_ENTITY_KEY, turretEntity);

    // if somehow turret is not valid
    if (!is_valid_ent(turretEntity)) 
    {
        return;
    }

    // if turret is not moving don't do anyting
    if (!isTurretMoving(turretEntity))
    {
        return;
    }

    // get turret origin
    static Float:turretOrigin[3];
    entity_get_vector(turretEntity, EV_VEC_origin, turretOrigin);
    turretOrigin[2] += 1.0;

    // update range position
    entity_set_vector(ent, EV_VEC_origin, turretOrigin);

    // update next position
    entity_set_float(ent, EV_FL_nextthink, get_gametime() + 0.1);
}

@createRangerEnt(turretEntity, Float:range, r, g, b)
{
    // create entity
    new ent = create_entity("env_sprite");

    // set basic properties
    entity_set_string(ent, EV_SZ_classname, RANGER_CLASSNAME);
    entity_set_model(ent, "sprites/TDNew/ranger.spr")

    // turn ranger flat to floor
    new Float:fFloatVal[3];
    entity_get_vector(ent, EV_VEC_angles, fFloatVal);
    fFloatVal[0] += 90
    entity_set_vector(ent, EV_VEC_angles, fFloatVal);

    // attach to turret
    entity_get_vector(turretEntity, EV_VEC_origin, fFloatVal);
    fFloatVal[2] += 1.0; // make it some above floor
    entity_set_origin(ent, fFloatVal);

    // set range
    entity_set_float(ent, EV_FL_scale, range / 250.0)

    // set attached entity
    CED_SetCell(ent, CED_RANGER_TURRET_ENTITY_KEY, turretEntity);

    // set owner by turret's owner
    new ownerId = getTurretOwner(turretEntity);
    CED_SetCell(ent, CED_RANGER_OWNER_KEY, ownerId);

    // add some color
    fm_set_rendering(ent, kRenderFxNone, r, g, b, kRenderTransAdd, 255);

    // update ranger position
    entity_set_float(ent, EV_FL_nextthink, get_gametime() + 0.1);

    return ent;
}

@getTurretRangeLevel(ent)
{
    new rangeLevel;

    // if turret doesn't have range level show smallest one
    if (!CED_GetCell(ent, CED_TURRET_RANGE_LEVEL, rangeLevel))
    {
        rangeLevel = 1
    }

    return rangeLevel;
}