#if defined td_engine_common_includes
  #endinput
#endif
#define td_engine_common_includes

// map entites
new g_MapEntityData[MAP_ENTITIES_ENUM];

// configuration
new any:g_MapConfiguration[MAP_CONFIGURATION_ENUM];
new Trie:g_MapConfigurationKeysTrie;

// models
new g_Models[MODELS_ENUM][MODELS_CONFIG_PATH_LENGTH];
new Trie:g_ModelsConfigurationKeysTrie;
new Array:g_ModelsPrecacheIdArray;

// wave
new Array:g_WaveDataArray;
new Array:g_MonstersEntArray;
new Trie:g_MonsterTypesConfigurationKeysTrie;

new Trie:g_WavesConfigurationKeysTrie;

// sounds
new Trie:g_SoundsConfigurationKeysTrie;
new Array:g_SoundsConfigurationPathsArray;

// common
new bool:g_IsGamePossible = true;
new bool:g_HasAnyTracks = false;

// monsters
new g_AliveMonstersNum;
new g_SentMonsters;

public getConfigDirectory()
{
    new const configDirectory[] = CONFIG_DIRECTORY;
    return configDirectory;
}

public setGameStatus(const bool:status) 
{
    g_IsGamePossible = status;
}

public bool:getGameStatus()
{
    return g_IsGamePossible;
}

public setMapEntityData(MAP_ENTITIES_ENUM:item, any:value)
{
    g_MapEntityData[item] = value;
}

public getMapEntityData(MAP_ENTITIES_ENUM:item)
{
    return g_MapEntityData[item];
}

public setMapConfigurationData(MAP_CONFIGURATION_ENUM:item, any:value)
{
    g_MapConfiguration[item] = value;
}

public any:getMapConfigurationData(MAP_CONFIGURATION_ENUM:item)
{
    return g_MapConfiguration[item];
}

public getMapEntityOrigin(MAP_ENTITIES_ENUM:item, Float:outputOrigin[3])
{
    new const entity = g_MapEntityData[item];
    entity_get_vector(entity, EV_VEC_origin, outputOrigin);
}

public keyToString(keyIndex)
{
    new key[6];
    num_to_str(keyIndex, key, charsmax(key));
    return key;
}

public getGlobalEnt(const entityName[])
{
    return find_ent_by_tname(-1, entityName);
}

public bool:isMonster(entity)
{
    return is_valid_ent(entity) && ((getEntityBitData(entity) & MONSTER_BIT) == MONSTER_BIT);
}

public isTrieValid(Trie:trie, key[], &type)
{
    return TrieKeyExists(trie, key) && TrieGetCell(trie, key, type);
}

public getMonsterClassName(monsterEntityName[], monsterTypeName[])
{
    format(monsterEntityName, 63, "%s_%s", MONSTER_ENTITY_NAME, monsterTypeName);
}

public bool:isMonsterKilled(entity)
{
    return is_valid_ent(entity) && ((getEntityBitData(entity) & MONSTER_KILLED_BIT) == MONSTER_KILLED_BIT);
}

public bool:isTrackWall(entity)
{
    return is_valid_ent(entity) && ((getEntityBitData(entity) & TRACK_WALL_BIT) == TRACK_WALL_BIT);
}

public bool:isEndWall(entity)
{
    return is_valid_ent(entity) && ((getEntityBitData(entity) & END_WALL_BIT) == END_WALL_BIT);
}

public bool:isHealthBar(entity)
{
    return is_valid_ent(entity) && ((getEntityBitData(entity) & MONSTER_HEALTHBAR_BIT) == MONSTER_HEALTHBAR_BIT);
}

public getEntityBitData(entity)
{
    return entity_get_int(entity, EV_INT_iuser1);
}

public setEntityBitData(entity, bitData)
{
    entity_set_int(entity, EV_INT_iuser1, bitData);
}

public playSoundGlobalRandom(SOUND_ENUM:sound)
{
    new soundPath[128];
    getRandomSoundFromSoundArray(sound, soundPath, 127);
   
    client_cmd(0, "spk %s", soundPath);
}

public playSoundAroundEntRandom(ent, SOUND_ENUM:sound)
{
    new soundPath[128];
    getRandomSoundFromSoundArray(sound, soundPath, 127);
   
    emit_sound(ent, CHAN_AUTO, soundPath, 1.0, ATTN_NORM, 0, PITCH_NORM);
}

public getRandomSoundFromSoundArray(SOUND_ENUM:sound, soundPath[], len)
{
    // get sound array
    new Array:soundArray = ArrayGetCell(g_SoundsConfigurationPathsArray, _:sound);
    
    // get number of sounds
    new size = ArraySize(soundArray);

    // calculate random sound index
    new soundIndex = random(size);

    ArrayGetString(soundArray, soundIndex, soundPath, len);
}

stock getTrackEntityName(trackId, trackName[9] = {})
{
    formatex(trackName, charsmax(trackName), "track%d", trackId);
    return trackName
}

stock getTrackWallEntityName(trackId, trackName[14] = {})
{
    formatex(trackName, charsmax(trackName), "track%d_wall", trackId);
    return trackName
}

stock getModelPrecacheId(MODELS_ENUM:model) 
{
    return ArrayGetCell(g_ModelsPrecacheIdArray, _:model);
}

stock createBloodEffectOnEntity(ent, size)
{ 
    if (!is_valid_ent(ent)) 
    {
        return;
    }

    new iOrigin[3];
    new Float:fOrigin[3];
    entity_get_vector(ent, EV_VEC_origin, fOrigin);

    FVecIVec(fOrigin, iOrigin);

    iOrigin[0] += random_num(-10, 10);
    iOrigin[1] += random_num(-10, 10);
    iOrigin[2] += random_num(-10, 30);

    message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
    write_byte(TE_BLOODSPRITE);
    write_coord(iOrigin[0] + random_num(-20,20));
    write_coord(iOrigin[1] + random_num(-20,20));
    write_coord(iOrigin[2] + random_num(-20,20));
    write_short(getModelPrecacheId(BLOODSPRAY_SPRITE_MODEL));
    write_short(getModelPrecacheId(BLOOD_SPRITE_MODEL));
    write_byte(229); // color index
    write_byte(size); // size
    message_end();
}

stock entity_set_aim(ent1, ent2)
{
    if(!is_valid_ent(ent1) || !is_valid_ent(ent2) || ent1 == ent2)
    {
        return 0;
    }

    static Float:offset[3];
    static Float:ent1origin[3];
    static Float:ent2origin[3];
    static Float:view_angles[3];

    entity_get_vector(ent2, EV_VEC_origin, ent2origin);
    entity_get_vector(ent1, EV_VEC_origin, ent1origin);

    static Float:ent2_angles[3];
    entity_get_vector(ent2, EV_VEC_v_angle, ent2_angles);
    ent2origin[0] += offset[0] * (((floatabs(ent2_angles[1]) - 90) / 90) * -1);
    ent2origin[1] += offset[1] * (1 - (floatabs(90 - floatabs(ent2_angles[1])) / 90));
    ent2origin[2] += offset[2];

    ent2origin[0] -= ent1origin[0];
    ent2origin[1] -= ent1origin[1];
    ent2origin[2] -= ent1origin[2];

    static Float:hyp;
    hyp = floatsqroot( (ent2origin[0] * ent2origin[0]) + (ent2origin[1] * ent2origin[1]));

    static x, y, z;
    x=0, y=0, z=0;

    if(ent2origin[0]>=0.0)  x=1;
    if(ent2origin[1]>=0.0)  y=1;
    if(ent2origin[2]>=0.0)  z=1;

    if(ent2origin[0]==0.0) ent2origin[0] = 0.000001;
    if(ent2origin[1]==0.0) ent2origin[1] = 0.000001;
    if(ent2origin[2]==0.0) ent2origin[2] = 0.000001;

    ent2origin[0]=floatabs(ent2origin[0]);
    ent2origin[1]=floatabs(ent2origin[1]);
    ent2origin[2]=floatabs(ent2origin[2]);

    view_angles[1] = floatatan2(ent2origin[1],ent2origin[0],degrees);

    if(x && !y) view_angles[1] = -1 * ( 180 - view_angles[1] );
    if(!x && !y) view_angles[1] = ( 180 - view_angles[1] );
    if(!x && y) view_angles[1] = view_angles[1] = 180 + floatabs(180 - view_angles[1]);
    if(x && !y) view_angles[1] = view_angles[1] = 0 - floatabs(-180 - view_angles[1]);
    if(!x && !y) view_angles[1] *= -1;

    while(view_angles[1] > 180.0)  view_angles[1] -= 180;
    while(view_angles[1] < -180.0) view_angles[1] += 180;

    if(view_angles[1]==180.0 || view_angles[1]==-180.0) view_angles[1]=-179.999999;
    view_angles[0] = floatasin(ent2origin[2] / hyp, degrees);

    if(z) view_angles[0] *= -1

    entity_set_int(ent1, EV_INT_fixangle, 1);
    entity_set_vector(ent1, EV_VEC_v_angle, view_angles);
    entity_set_vector(ent1, EV_VEC_angles, view_angles);
    entity_set_int(ent1, EV_INT_fixangle, 1);

    return 1;
}
