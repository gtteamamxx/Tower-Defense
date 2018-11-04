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
        log_amx("Plik konfiguracyjny modeli %s nie istnieje.", modelsConfigurationFilePath);
    }
    else 
    {
        loadModelsConfigurationFromFile(modelsConfigurationFilePath);
    }

    @releaseModelsConfigurationDictionary();
}

public loadMapConfiguration()
{
    @loadMapConfigurationFromConfigurationFile();
    @releaseMapConfigurationDictionary();

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
}

@checkEntities()
{
    new const startEntity = getMapEntityData(START_ENTITY);
    new const endEntity = getMapEntityData(END_ENTITY);

    if(!is_valid_ent(startEntity) || !is_valid_ent(endEntity))
    {
        log_amx("[Map] Mapa nie posiada punktu startu 'start' albo punktu końcowego 'end'")
        setGameStatus(.status = false);
    }

    new const endWallEntity = @getGlobalEnt(MAP_END_TRACK_ENTITY_NAME);
    if(!is_valid_ent(endWallEntity))
    {
        log_amx("[Map] Mapa nie posiada końcowego punktu dotyku dla potwórów.")
        setGameStatus(.status = false);
    }

    new const track1Entity = @getGlobalEnt(getTrackEntityName(.trackId = 1));
    if(!is_valid_ent(track1Entity))
    {
        log_amx("[Map] Mapa nie posiada żadnego punktu odpowiedzialnego za trasę. Mogą wystąpić błędy.");
    }
}

@hideAllTrackWallEntities()
{
    new trackIndex = 1, trackWallEntity;
    while((trackWallEntity = @getGlobalEnt(getTrackWallEntityName(.trackId = trackIndex++))))
    {
        if(is_valid_ent(trackWallEntity))
        {
            @hideEntity(trackWallEntity);
        }
    }

    new const endWallEntity = @getGlobalEnt(MAP_END_TRACK_ENTITY_NAME);
    if(is_valid_ent(endWallEntity))
    {
        @hideEntity(endWallEntity);
    }
}

@loadMapConfigurationFromConfigurationFile()
{
    new configurationFilePath[128];
    getMapConfigurationFilePath(configurationFilePath);

    if(!file_exists(configurationFilePath))
    {
        log_amx("Plik konfiguracyjny %s dla tej mapy nie istnieje.", configurationFilePath);
        getMapConfigurationFilePath(configurationFilePath, .useDefaultConfig = true);

        if(!file_exists(configurationFilePath))
        {
            log_amx("Nie istnieje domyślny plik konfiguracyjny.");
            setGameStatus(.status = false);
            return;
        }
    }

    loadMapConfigFromJsonFile(configurationFilePath);
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
    new towerEntity = create_entity("info_target")

    entity_set_string(towerEntity, EV_SZ_classname, TOWER_ENTITY_NAME)
    entity_set_model(towerEntity, g_Models[TOWER_MODEL]);

    entity_set_vector(towerEntity, EV_VEC_origin, origin);

    entity_set_int(towerEntity, EV_INT_solid, SOLID_NOT);
    entity_set_int(towerEntity, EV_INT_movetype, MOVETYPE_FLY) 
    
    drop_to_floor(towerEntity)

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
    new spriteEntity = create_entity("env_sprite")
    
    entity_set_string(spriteEntity, EV_SZ_classname, entityName)
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
    return @getGlobalEnt(MAP_START_ENTITY_NAME);
}

@getEndEntity()
{
    return @getGlobalEnt(MAP_END_ENTITY_NAME);
}

@getGlobalEnt(const entityName[])
{
    return find_ent_by_tname(-1, entityName);
}

@getModelsConfigurationFilePath(path[128])
{
    formatex(path, charsmax(path), "%s/%s.json", getConfigDirectory(), MODELS_CONFIG_FILE);
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