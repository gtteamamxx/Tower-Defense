#if defined td_json_monsters_manager_included
  #endinput
#endif
#define td_json_monsters_manager_included

#define MONSTER_DATA_TYPE_KEY "monster_type"
#define MONSTER_DATA_TRACK_KEY "monster_track"
#define MONSTER_DATA_MAX_HEALTH "monster_max_health"
#define MONSTER_DATA_MAX_SPEED "monster_max_speed"
#define MONSTER_DATA_SPEED "monster_speed"

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
            actualMonsterTrack = -1;
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
    new Float:delay = getRandomValueForMonsterTypeInWave(wave, monsterTypeIndex, DEPLOY_EXTRA_DELAY);

    if(delay == -1.0)
    {
        delay == 0.0;
    }

    getMonsterTypeNameForMonsterTypeInWave(wave, monsterTypeIndex, monsterTypeName);
    client_print(0, 3, "Sending %d monster of type: %s. Waiting: %0.1fs", count, monsterTypeName, delay);

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

    new Float:monsterHealth = getRandomValueForMonsterTypeInWave(wave, monsterTypeIndex, HEALTH);
    new Float:monsterSpeed = getRandomValueForMonsterTypeInWave(wave, monsterTypeIndex, SPEED);
    new Float:deployInterval = getRandomValueForMonsterTypeInWave(wave, monsterTypeIndex, DEPLOY_INTERVAL);

    new Array:sendMonsterParameterArray = ArrayCreate();
    ArrayPushCell(sendMonsterParameterArray, monsterHealth);
    ArrayPushCell(sendMonsterParameterArray, monsterSpeed);
    ArrayPushCell(sendMonsterParameterArray, monsterTypeIndex);
    ArrayPushCell(sendMonsterParameterArray, wave);

    client_print(0, 3, "Monsters left: %d Waiting: %0.1f", monstersLeft, deployInterval);
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

    if(equal(monsterModel[0], "")) 
    {
        log_amx("Brak modeli dla typu potworu: %s", monsterTypeName);
        return;
    }

    client_print(0, 3, "sending monster of type: %s hp: %0.1f speed: %0.1f. Using model: %s", monsterTypeName, monsterHealth, monsterSpeed, monsterModel);

    @createMonsterEntity(monsterTypeName, monsterHealth, monsterSpeed, monsterModel);
}

@createMonsterEntity(monsterTypeName[33], Float:monsterHealth, Float:monsterSpeed, monsterModel[128])
{
    new monsterEntity = cs_create_entity("info_target");
    if(monsterEntity == 0 )
    {
        log_amx("Creating monster entity failed");
        return;
    }

    g_AliveMonstersNum++;
    g_SentMonsters++;

    @setMonsterClass(monsterEntity, monsterTypeName);
    @setMonsterModel(monsterEntity, monsterModel);
    @setMonsterPosition(monsterEntity);

    @setMonsterProperties(monsterEntity, monsterHealth, monsterSpeed);
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
    set_pev(monsterEntity, pev_groupinfo, (1 << g_SentMonsters) );
}

@setMonsterBitData(monsterEntity)
{
    entity_set_int(monsterEntity, EV_INT_iuser1, MONSTER_BIT);
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

    static Float:velocity_vector[3];

    new Float:monsterSpeed; CED_GetCell(monsterEntity, MONSTER_DATA_SPEED, monsterSpeed);
    velocity_by_aim(monsterEntity, floatround(monsterSpeed), velocity_vector);
    entity_set_vector(monsterEntity, EV_VEC_velocity, velocity_vector);
}