#if defined td_json_monsters_manager_included
  #endinput
#endif
#define td_json_monsters_manager_included

#define MONSTER_DATA_TYPE_KEY "monster_type"
#define MONSTER_DATA_TRACK_KEY "monster_track"
#define MONSTER_DATA_MAX_HEALTH "monster_max_health"
#define MONSTER_DATA_MAX_SPEED "monster_max_speed"
#define MONSTER_DATA_SPEED "monster_speed"
#define MONSTER_DATA_HEALTHBAR_ENTITY "monster_healthbar"
#define MONSTER_DATA_IS_LAST_SHOT_HEADSHOT "monster_headshot"

public monsterShotTraceAttack(monsterEntity, playerId, Float:damage, Float:direction[3], traceHandle, damageTypeBit)
{
    if(!isMonster(monsterEntity) || !is_user_connected(playerId))
    {
        return;
    }

    new bool:isPlayerShotHeadShot = get_tr2(traceHandle, TR_iHitgroup) == HIT_HEAD;

    CED_SetCell(monsterEntity, MONSTER_DATA_IS_LAST_SHOT_HEADSHOT, _:isPlayerShotHeadShot);
}

public constrollDamageTakenToMonster(monsterEntity, inflictorId, playerId, Float:damage, damageTypeBit)
{
    if(!isMonster(monsterEntity) || !is_user_connected(playerId))
    {
        return;
    }

    new isDamageTakedByGun = damageTypeBit & DMG_BULLET;
    if(isDamageTakedByGun)
    {
        damage = @controllDamageTakenToMonsterByGun(monsterEntity, playerId, damage);
    }

    SetHamParamFloat(4, damage);
}

public showMonsterTakedDamage(monsterEntity, inflictorId, playerId, Float:damage, damageTypeBit)
{
    if(!isMonster(monsterEntity) || !is_user_connected(playerId))
    {
        return;
    }

    new bool:isPlayerShotHeadShot; CED_GetCell(monsterEntity, MONSTER_DATA_IS_LAST_SHOT_HEADSHOT, isPlayerShotHeadShot);
    new Float:actualMonsterHealth = entity_get_float(monsterEntity, EV_FL_health);

    set_hudmessage(0, 255, 0, 0.55, -1.0, 0, 0.0, 0.1)
    show_hudmessage(playerId, "%d%s", floatround(damage), isPlayerShotHeadShot ? " HS" : "");

    set_dhudmessage(255, 255, 255, -1.0, -1.0, 0, 0.0, 0.1);
    show_dhudmessage(playerId, "x");

    client_print(playerId, print_center, "HP: %0.0f", actualMonsterHealth);

    @updateMonsterHealthbar(monsterEntity, actualMonsterHealth);
}

public monsterKilled(monsterEntity, playerId)
{
    if(!isMonster(monsterEntity))
    {
        return HAM_IGNORED;
    }

    client_print(0, 3, "killed monster: %d", monsterEntity);
    @setMonsterKilledProperties(monsterEntity);
    @setMonsterKilledAnimation(monsterEntity);
    @removeMonsterHealthbar(monsterEntity);

    new removeMonsterEntityParameter[1];
    removeMonsterEntityParameter[0] = monsterEntity;

    set_task(6.0, "@removeMonsterEntity", .parameter = removeMonsterEntityParameter, .len = 1);

    return HAM_SUPERCEDE;
}

@removeMonsterEntity(removeMonsterEntityParameter[1])
{
    new monsterEntity = removeMonsterEntityParameter[0];
    if(is_valid_ent(monsterEntity))
    {
        remove_entity(monsterEntity);
    }
}

@removeMonsterHealthbar(monsterEntity)
{
    new healthBarEntity; CED_GetCell(monsterEntity, MONSTER_DATA_HEALTHBAR_ENTITY, healthBarEntity);
    if(isHealthBar(healthBarEntity))
    {
        remove_entity(healthBarEntity);
    }
    CED_SetCell(monsterEntity, MONSTER_DATA_HEALTHBAR_ENTITY, -1);
}

@setMonsterKilledProperties(monsterEntity)
{
    entity_set_int(monsterEntity, EV_INT_solid, SOLID_NOT);
    entity_set_float(monsterEntity, EV_FL_framerate, 0.9);
    cs_set_ent_class(monsterEntity, MONSTER_DEAD_ENTITY_NAME);
    entity_set_vector(monsterEntity, EV_VEC_velocity, Float:{0.0, 0.0, -2.5});
}

@setMonsterKilledAnimation(monsterEntity)
{
    new bool:isMonsterKilledByHeadShot; CED_GetCell(monsterEntity, MONSTER_DATA_IS_LAST_SHOT_HEADSHOT, isMonsterKilledByHeadShot);
    new deathSequence = lookup_sequence(monsterEntity, "head") ;

    if(!isMonsterKilledByHeadShot)
    {
        new randomDeathSequence = random_num(1, 3), deathSequenceName[7];
        formatex(deathSequenceName, charsmax(deathSequenceName), "death%d", randomDeathSequence);

        deathSequence = lookup_sequence(monsterEntity, deathSequenceName);
        if(!deathSequence)
        {
            deathSequence = lookup_sequence(monsterEntity, "death1");
        }
    }

    entity_set_int(monsterEntity, EV_INT_sequence, deathSequence);
    entity_set_float(monsterEntity, EV_FL_animtime, get_gametime());
}

@updateMonsterHealthbar(monsterEntity, Float:actualMonsterHealth)
{
    new monsterHealthbarEntity; CED_GetCell(monsterEntity, MONSTER_DATA_HEALTHBAR_ENTITY, monsterHealthbarEntity);
    if(!isHealthBar(monsterHealthbarEntity))
    {
        return;
    }

    new Float:monsterMaxHealth; CED_GetCell(monsterEntity, MONSTER_DATA_MAX_HEALTH, monsterMaxHealth);

    if(monsterMaxHealth != 0)
    {
        new Float:healthbarFrame = (0.0 + actualMonsterHealth * 100 ) / monsterMaxHealth;
        entity_set_float(monsterHealthbarEntity, EV_FL_frame, healthbarFrame);
    }
}

Float:@controllDamageTakenToMonsterByGun(monsterEntity, playerId, Float:damage)
{
    new bool:isPlayerShotHeadShot; CED_GetCell(monsterEntity, MONSTER_DATA_IS_LAST_SHOT_HEADSHOT, isPlayerShotHeadShot);
    if(isPlayerShotHeadShot)
    {
        damage *= 4.0;
    }

    return damage;
}

public startSendingWaveMonsters(wave)
{
    @startSendingWaveMonsters(wave, .monsterTypeIndex = 0);
}

public monsterChangeTrack(monsterEntity, wallEntity)
{
    if(!isMonster(monsterEntity)) 
    {
        return;
    }

    if(isTrackWall(wallEntity))
    {
        new actualMonsterTrack; CED_GetCell(monsterEntity, MONSTER_DATA_TRACK_KEY, actualMonsterTrack);
        actualMonsterTrack++;

        new trackEntity = getGlobalEnt(getTrackEntityName(.trackId = actualMonsterTrack));
        if(!is_valid_ent(trackEntity))
        {
            trackEntity = getMapEntityData(END_ENTITY);
            actualMonsterTrack = MONSTER_TARGET_END_ID;
        }

        CED_SetCell(monsterEntity, MONSTER_DATA_TRACK_KEY, actualMonsterTrack);
        aimMonsterToTrack(monsterEntity, trackEntity);
    }
    else if(isEndWall(wallEntity))
    {
        @monsterTouchedEndWall(monsterEntity);
    }
}

@monsterTouchedEndWall(monsterEntity)
{
    g_AliveMonstersNum--;
    remove_entity(monsterEntity);
}

@startSendingWaveMonsters(wave, monsterTypeIndex)
{
    new monsterTypeName[33];
    new count = getNumberOfMonstersForMonsterTypeInWave(wave, monsterTypeIndex);
    new Float:delay = getRandomValueForMonsterTypeInWave(wave, monsterTypeIndex, MONSTER_DEPLOY_EXTRA_DELAY);

    getMonsterTypeNameForMonsterTypeInWave(wave, monsterTypeIndex, monsterTypeName);

    new sendWaveMonsterParameter[3];
    sendWaveMonsterParameter[0] = wave;
    sendWaveMonsterParameter[1] = monsterTypeIndex;
    sendWaveMonsterParameter[2] = count;

    set_task(delay, "@sendMonsterAndAfterSendNextOne", .parameter = sendWaveMonsterParameter, .len = 3);
}

@sendMonsterAndAfterSendNextOne(sendWaveMonsterParameter[3])
{
    new wave = sendWaveMonsterParameter[0];
    new monsterTypeIndex = sendWaveMonsterParameter[1];
    new monstersLeft = sendWaveMonsterParameter[2];

    if(monstersLeft == 0)
    {
        if(monsterTypeIndex + 1 < getWaveMonsterTypesNum(wave))
        {
            @startSendingWaveMonsters(wave, monsterTypeIndex + 1);
        }
        return;
    }

    new Float:monsterHealth = getRandomValueForMonsterTypeInWave(wave, monsterTypeIndex, MONSTER_HEALTH);
    new Float:monsterSpeed = getRandomValueForMonsterTypeInWave(wave, monsterTypeIndex, MONSTER_SPEED);
    new Float:deployInterval = getRandomValueForMonsterTypeInWave(wave, monsterTypeIndex, MONSTER_DEPLOY_INTERVAL);

    new Array:sendMonsterParameterArray = ArrayCreate();
    ArrayPushCell(sendMonsterParameterArray, monsterHealth);
    ArrayPushCell(sendMonsterParameterArray, monsterSpeed);
    ArrayPushCell(sendMonsterParameterArray, monsterTypeIndex);
    ArrayPushCell(sendMonsterParameterArray, wave);

    @sendMonster(sendMonsterParameterArray);

    sendWaveMonsterParameter[2] = monstersLeft - 1;
    set_task(deployInterval, "@sendMonsterAndAfterSendNextOne", .parameter = sendWaveMonsterParameter, .len = 3);
}

@sendMonster(Array:sendMonsterParameterArray)
{
    new Float:monsterHealth = Float:ArrayGetCell(sendMonsterParameterArray, 0);
    new Float:monsterSpeed = Float:ArrayGetCell(sendMonsterParameterArray, 1);
    new monsterTypeIndex = ArrayGetCell(sendMonsterParameterArray, 2);
    new wave = ArrayGetCell(sendMonsterParameterArray, 3);

    ArrayDestroy(sendMonsterParameterArray);

    new monsterTypeName[33]; getMonsterTypeNameForMonsterTypeInWave(wave, monsterTypeIndex, monsterTypeName);
    new monsterModel[128]; gerRandomModelOfMonsterType(monsterTypeName, monsterModel);

    if(equal(monsterModel[0], EMPTY_STRING)) 
    {
        log_amx("No models for monster type: %s", monsterTypeName);
        return;
    }

    @createMonsterEntity(monsterTypeName, monsterHealth, monsterSpeed, monsterModel);
}

@createMonsterEntity(monsterTypeName[33], Float:monsterHealth, Float:monsterSpeed, monsterModel[128])
{
    new monsterEntity = cs_create_entity("info_target");
    if(monsterEntity == 0)
    {
        log_amx("Creating monster entity failed.");
        return;
    }

    g_AliveMonstersNum++;
    g_SentMonsters++;

    @setMonsterClass(monsterEntity, monsterTypeName);
    @setMonsterModel(monsterEntity, monsterModel);
    @setMonsterPosition(monsterEntity);

    @setMonsterProperties(monsterEntity, monsterHealth, monsterSpeed);
    @createMonsterHealthBar(monsterEntity);
}

@createMonsterHealthBar(monsterEntity)
{
    new healthBarEntity = cs_create_entity("env_sprite");

    if(healthBarEntity == 0)
    {
        log_amx("Creating health bar entity failed.");
        return;
    }

    cs_set_ent_class(healthBarEntity, MONSTER_HEALTHBAR_ENTITY_NAME);
    
    entity_set_model(healthBarEntity, g_Models[HEALTHBAR_SPRITE_MODEL]);

    entity_set_int(healthBarEntity, EV_INT_solid, SOLID_NOT);
    entity_set_int(healthBarEntity, EV_INT_movetype, MOVETYPE_FLY);

    entity_set_float(healthBarEntity , EV_FL_frame , 99.0 );
    entity_set_float(healthBarEntity , EV_FL_scale , 0.4 );

    setEntityBitData(healthBarEntity, MONSTER_HEALTHBAR_BIT);

    CED_SetCell(monsterEntity, MONSTER_DATA_HEALTHBAR_ENTITY, healthBarEntity);
}

@setMonsterProperties(monsterEntity, Float:monsterHealth, Float:monsterSpeed)
{
    @setMonsterHealth(monsterEntity, monsterHealth);
    @setMonsterSpeed(monsterEntity, monsterSpeed);

    @setMonsterCollision(monsterEntity);
    @setMonsterBitData(monsterEntity);
    @setMonsterAnimationBySpeed(monsterEntity, monsterSpeed);
    @setMonsterTargetTrack(monsterEntity);
}

@setMonsterClass(monsterEntity, monsterTypeName[33])
{
    cs_set_ent_class(monsterEntity, MONSTER_ENTITY_NAME);
    CED_SetString(monsterEntity, MONSTER_DATA_TYPE_KEY, monsterTypeName);
}

@setMonsterModel(monsterEntity, monsterModel[128])
{
    entity_set_model(monsterEntity, monsterModel);

    entity_set_int(monsterEntity, EV_INT_solid, SOLID_BBOX);
    entity_set_int(monsterEntity, EV_INT_movetype, MOVETYPE_FLY);
    entity_set_float(monsterEntity, EV_FL_takedamage, DAMAGE_YES);

    entity_set_size(monsterEntity, Float:{-15.0, -15.0, -20.0}, Float:{15.0, 15.0, 56.0});	
}

@setMonsterPosition(monsterEntity)
{
    entity_set_vector(monsterEntity, EV_VEC_origin, @getStartEntityOrigin());
}

@setMonsterCollision(monsterEntity)
{
    set_pev(monsterEntity, pev_groupinfo, (1 << g_SentMonsters));
}

@setMonsterBitData(monsterEntity)
{
    setEntityBitData(monsterEntity, MONSTER_BIT);
}

@setMonsterAnimationBySpeed(monsterEntity, Float:monsterSpeed)
{
    entity_set_int(monsterEntity, EV_INT_sequence, ANIMATION_RUN_SEQUENCE_ID);
    entity_set_float(monsterEntity, EV_FL_animtime, 1.0);    
    entity_set_float(monsterEntity, EV_FL_framerate, monsterSpeed / MONSTER_ANIMATION_SPEED_DIVIDER);
}

@setMonsterTargetTrack(monsterEntity)
{
    new trackId = g_HasAnyTracks ? 1 : MONSTER_TARGET_END_ID;
    new trackEntity = @getMonsterFirstTrackEntity();

    CED_SetCell(monsterEntity, MONSTER_DATA_TRACK_KEY, trackId);
    aimMonsterToTrack(monsterEntity, trackEntity);
}

@setMonsterHealth(monsterEntity, Float:monsterHealth)
{
    entity_set_float(monsterEntity, EV_FL_health, monsterHealth);
    CED_SetCell(monsterEntity, MONSTER_DATA_MAX_HEALTH, monsterHealth);
}

@setMonsterSpeed(monsterEntity, Float:monsterSpeed)
{
    CED_SetCell(monsterEntity, MONSTER_DATA_MAX_SPEED, monsterSpeed);
    CED_SetCell(monsterEntity, MONSTER_DATA_SPEED, monsterSpeed);
}

any:@getStartEntityOrigin()
{
    static Float:startOrigin[3];
    if(startOrigin[0] == 0.0 && startOrigin[1] == 0.0 && startOrigin[2] == 0.0) 
    {
        new startEntity = getMapEntityData(START_ENTITY);
        entity_get_vector(startEntity, EV_VEC_origin, startOrigin)
    }
    return startOrigin;
}

@getMonsterFirstTrackEntity()
{
    static target;
    if(!is_valid_ent(target))
    {
        target = getGlobalEnt(getTrackEntityName(.trackId = 1));
        if(!is_valid_ent(target))
        {
            target = getMapEntityData(END_ENTITY);
        }
    }

    return target;
}

stock aimMonsterToTrack(monsterEntity, trackEntity = -1)
{
    if(trackEntity == -1)
    {
        new actualMonsterTrack; CED_GetCell(monsterEntity, MONSTER_DATA_TRACK_KEY, actualMonsterTrack);
        trackEntity = getGlobalEnt(getTrackEntityName(.trackId = actualMonsterTrack));
    }

    entity_set_aim(monsterEntity, trackEntity);

    static Float:velocityVector[3];

    new Float:monsterSpeed; CED_GetCell(monsterEntity, MONSTER_DATA_SPEED, monsterSpeed);
    velocity_by_aim(monsterEntity, floatround(monsterSpeed), velocityVector);
    entity_set_vector(monsterEntity, EV_VEC_velocity, velocityVector);
}