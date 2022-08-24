#if defined td_engine_startup_includes
  #endinput
#endif
#define td_engine_startup_includes

public loadModelsConfiguration()
{
    new modelsConfigurationFilePath[128];
    @getModelsConfigurationFilePath(modelsConfigurationFilePath);

    if(!file_exists(modelsConfigurationFilePath))
    {
        log_amx("[Models] Configuration file %s for models doesn't exist.", modelsConfigurationFilePath);
    }
    else 
    {
        loadModelsConfigurationFromFile(modelsConfigurationFilePath);
    }

    @releaseModelsConfigurationDictionary();
}

public loadSoundsConfiguration()
{
    new soundsConfigurationFilePath[128];
    @getSoundsConfigurationFilePath(soundsConfigurationFilePath);
    
    if(!file_exists(soundsConfigurationFilePath))
    {
        log_amx("[Models] Configuration file %s for sounds doesn't exist.", soundsConfigurationFilePath);
    }
    else 
    {
        loadSoundsConfigurationFromFile(soundsConfigurationFilePath);
    }

    @releaseSoundsConfigurationDictionary();
}

public loadMapConfiguration()
{
    @loadMapConfigurationFromConfigurationFile();

    @setStartEntities();
    @setEndEntities();
}

public checkGamePossibility()
{
    @checkEntities();
}

public initializeGame()
{
    @hideAllTrackWallEntities();
    @showWaveConfig();
}

@showWaveConfig()
{
    new wavesNum = ArraySize(g_WaveDataArray);
    for(new i = 0; i < wavesNum; ++i)
    {
        new Array:waveArray = Array:ArrayGetCell(g_WaveDataArray, i);

        log_amx("WAVE: %d", i + 1);

        new Trie:waveConfigurationTrie = Trie:ArrayGetCell(waveArray, _:WAVE_CONFIG);
        
        new TrieIter:configIter = TrieIterCreate(waveConfigurationTrie);
        while(!TrieIterEnded(configIter))
        {
            new iterKey[64], any:iterValue, iterValueString[64];
            TrieIterGetKey(configIter, iterKey, charsmax(iterKey));
            TrieIterGetCell(configIter, iterValue);
            num_to_str(iterValue, iterValueString, charsmax(iterValueString));

            log_amx("....Config: %s....value: num: %d string: %s", iterKey, iterValue, iterValueString);
            TrieIterNext(configIter);
        }

        TrieIterDestroy(configIter);

        new Array:monsterTypesArray = Array:ArrayGetCell(waveArray, _:WAVE_MONSTER_TYPES);
        new monstersTypeCount = ArraySize(monsterTypesArray);

        for(new j = 0; j < monstersTypeCount; ++j)
        {
            new Trie:monsterTypeTrie = Trie:ArrayGetCell(monsterTypesArray, j);

            log_amx("..%d..", j);   
            for(new k = 0; k < _:WAVE_MONSTER_DATA_ENUM; ++k)
            {
                new key[64];
                num_to_str(k, key, charsmax(key));

                if(WAVE_MONSTER_DATA_ENUM:k == MONSTER_TYPE)
                {
                    new type[64];
                    TrieGetString(monsterTypeTrie, key, type, charsmax(type));
                    log_amx("MONSTER_TYPE: %s", type);
                }
                else if(WAVE_MONSTER_DATA_ENUM:k == MONSTER_COUNT)
                {
                    new count[2];
                    TrieGetArray(monsterTypeTrie, key, count, 2);
                    log_amx("MONSTER_COUNT: %d - %d", count[0], count[1]);
                }
                else 
                {
                    new Float:value[2];
                    TrieGetArray(monsterTypeTrie, key, value, 2);
                    log_amx("%d: %.2f - %.2f", k, value[0], value[1]);
                }
            }
        }
    }
}

@checkEntities()
{
    new const startEntity = getMapEntityData(START_ENTITY);
    new const endEntity = getMapEntityData(END_ENTITY);

    if(!is_valid_ent(startEntity) || !is_valid_ent(endEntity))
    {
        log_amx("[Map] Map don't have 'start' or 'end' entity.")
        setGameStatus(.status = false);
    }

    new const endWallEntity = getGlobalEnt(MAP_END_TRACK_ENTITY_NAME);
    if(!is_valid_ent(endWallEntity))
    {
        log_amx("[Map] Map doesn't have 'end_wall' entitiy.")
        setGameStatus(.status = false);
    }

    new const track1Entity = getGlobalEnt(getTrackEntityName(.trackId = 1));
    if(!is_valid_ent(track1Entity))
    {
        log_amx("[Map] [Warning] Map doesn't have any 'track' entity. Errors may occur");
    }
    else
    {
        g_HasAnyTracks = true;
    }
}

@hideAllTrackWallEntities()
{
    new trackIndex = 1, trackWallEntity;
    while((trackWallEntity = getGlobalEnt(getTrackWallEntityName(.trackId = trackIndex++))))
    {
        if(is_valid_ent(trackWallEntity))
        {
            setEntityBitData(trackWallEntity, TRACK_WALL_BIT);
            @hideEntity(trackWallEntity);
        }
    }

    new const endWallEntity = getGlobalEnt(MAP_END_TRACK_ENTITY_NAME);
    if(is_valid_ent(endWallEntity))
    {
        setEntityBitData(endWallEntity, END_WALL_BIT);
        @hideEntity(endWallEntity);
    }
}

@loadMapConfigurationFromConfigurationFile()
{
    new configurationFilePath[128];
    getMapConfigurationFilePath(configurationFilePath);

    if(!file_exists(configurationFilePath))
    {
        log_amx("[CONFIGURATION] Configuration file %s doesn't exist.", configurationFilePath);
        getMapConfigurationFilePath(configurationFilePath, .useDefaultConfig = true);

        if(!file_exists(configurationFilePath))
        {
            log_amx("[CONFIGURATION] Even default configuration file doesn't exists.");
            setGameStatus(.status = false);
            return;
        }
    }

    loadMapConfigFromJsonFile(configurationFilePath);
    
    loadWavesFromFile(configurationFilePath);
    @releaseWavesConfigurationDictionary();

    @prepareRandomMonstersCountForWaves();

    executeOnConfigurationLoadForward(configurationFilePath, g_IsGamePossible);

    @releaseMapConfigurationDictionary();
}

@setStartEntities()
{
    @setStartEntity();
    @createStartSprite();
}

@setEndEntities()
{
    @setEndEntity();
    @createTower();
    @createEndSprite();
}

@setStartEntity()
{
    new const startEntity = @getStartEntity();
    setMapEntityData(START_ENTITY, startEntity);
}

@setEndEntity()
{
    new const endEntity = @getEndEntity();
    setMapEntityData(END_ENTITY, endEntity);
}

@createTower()
{
    new bool:shouldTowerBeVisible = getMapConfigurationData(SHOW_TOWER);
    if(shouldTowerBeVisible)
    {
        new Float:towerEntityOrigin[3];
        getMapEntityOrigin(END_ENTITY, .outputOrigin = towerEntityOrigin);

        new towerEntity = @createTowerEntity(.origin = towerEntityOrigin);
        setMapEntityData(TOWER_ENTITY, towerEntity);
    }
}

@createTowerEntity(Float:origin[3])
{
    new towerEntity = cs_create_entity("info_target")

    cs_set_ent_class(towerEntity, TOWER_ENTITY_NAME)
    entity_set_model(towerEntity, g_Models[TOWER_MODEL]);

    entity_set_vector(towerEntity, EV_VEC_origin, origin);

    entity_set_int(towerEntity, EV_INT_solid, SOLID_NOT);
    entity_set_int(towerEntity, EV_INT_movetype, MOVETYPE_FLY) 
    
    drop_to_floor(towerEntity)

    g_TowerHealth = getMapConfigurationData(TOWER_HEALTH);

    return towerEntity;
}

@createEndSprite()
{
    new bool:shouldEndSpriteBeVisible = getMapConfigurationData(SHOW_END_SPRITE);
    if(!shouldEndSpriteBeVisible)
    {
        return;
    }

    new Float:endSpriteEntityOrigin[3];
    getMapEntityOrigin(END_ENTITY, .outputOrigin = endSpriteEntityOrigin);

    new endSpriteEntity = @createCircleSprite(
        .entityName = END_SPRITE_ENTITY_NAME, 
        .origin = endSpriteEntityOrigin,
        .modelIndex = END_SPRITE_MODEL
    );

    setMapEntityData(END_SPRITE_ENTITY, endSpriteEntity);
}

@createStartSprite()
{
    new bool:shouldStartSpriteBeVisible = getMapConfigurationData(SHOW_START_SPRITE);
    if(!shouldStartSpriteBeVisible)
    {
        return;
    }

    new Float:startSpriteEntityOrigin[3];
    getMapEntityOrigin(START_ENTITY, .outputOrigin = startSpriteEntityOrigin);

    new startSpriteEntity = @createCircleSprite(
        .entityName = START_SPRITE_ENTITY_NAME, 
        .origin = startSpriteEntityOrigin,
        .modelIndex = START_SPRITE_MODEL
    );

    setMapEntityData(START_SPRITE_ENTITY, startSpriteEntity);
}

@createCircleSprite(const entityName[], Float:origin[3], MODELS_ENUM:modelIndex)
{
    new spriteEntity = cs_create_entity("env_sprite")
    
    cs_set_ent_class(spriteEntity, entityName)
    entity_set_model(spriteEntity, g_Models[modelIndex])
        
    entity_set_vector(spriteEntity, EV_VEC_origin, origin)
    entity_set_int(spriteEntity, EV_INT_solid, SOLID_NOT);
    entity_set_int(spriteEntity, EV_INT_movetype, MOVETYPE_FLY) 
    
    entity_set_float(spriteEntity, EV_FL_framerate, 1.0)
    entity_set_float(spriteEntity, EV_FL_scale, 2.5)

    return spriteEntity;
}

@getStartEntity()
{
    return getGlobalEnt(MAP_START_ENTITY_NAME);
}

@getEndEntity()
{
    return getGlobalEnt(MAP_END_ENTITY_NAME);
}

@getModelsConfigurationFilePath(path[128])
{
    formatex(path, charsmax(path), "%s/%s.json", getConfigDirectory(), MODELS_CONFIG_FILE);
}

@getSoundsConfigurationFilePath(path[128])
{
    formatex(path, charsmax(path), "%s/%s.json", getConfigDirectory(), SOUNDS_CONFIG_FILE);
}

@hideEntity(entity)
{
    fm_set_rendering(entity, .r = 0, .g = 0, .b = 0, .render = kRenderTransAdd, .amount = 0)
}

@releaseMapConfigurationDictionary()
{
    TrieDestroy(g_MapConfigurationKeysTrie);
}

@releaseModelsConfigurationDictionary()
{
    TrieDestroy(g_ModelsConfigurationKeysTrie);
}

@releaseSoundsConfigurationDictionary()
{
    TrieDestroy(g_SoundsConfigurationKeysTrie);
}

@releaseWavesConfigurationDictionary()
{
    TrieDestroy(g_WavesConfigurationKeysTrie);
    TrieDestroy(g_MonsterTypesConfigurationKeysTrie);
}

// Function fills wave monsters count array
// with randomly number of monsters per wave per monster type
//
// It's necessary due we need static number of monsters in wave
@prepareRandomMonstersCountForWaves()
{
    for(new i = 0; i < ArraySize(g_WaveDataArray); ++i)
    {
        new Array:waveArray = Array:ArrayGetCell(g_WaveDataArray, i);
        new Array:monsterTypesArray = Array:ArrayGetCell(waveArray, _:WAVE_MONSTER_TYPES);
        new Array:monstersCountArray = Array:ArrayGetCell(waveArray, _:WAVE_MONSTERS_COUNT);
        
        for(new j = 0; j < ArraySize(monsterTypesArray); ++j)
        {
            new Trie:monsterTypeTrie = Trie:ArrayGetCell(monsterTypesArray, j);

            new monsterTypeCount[2];
            TrieGetArray(monsterTypeTrie, keyToString(_:MONSTER_COUNT), monsterTypeCount, 2);

            new randomCount = random_num(monsterTypeCount[0], monsterTypeCount[1]);
            ArrayPushCell(monstersCountArray, randomCount);
        }
    }
}

stock getMapConfigurationFilePath(output[128], bool:useDefaultConfig = false)
{
    if(!useDefaultConfig) 
    {
        get_mapname(output, charsmax(output));
    }
    else 
    {
        output = DEFAULT_CONFIG_FILE;
    }

    format(output, charsmax(output), "%s/%s.json", getConfigDirectory(), output);
}