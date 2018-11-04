#if defined td_engine_startup_includes
  #endinput
#endif
#define td_engine_startup_includes

public loadMapConfiguration()
{
    @loadMapConfigurationFromConfigurationFile();
    @releaseMapConfigurationDictionary();

    @setStartEntities();
    @setEndEntities();
}

public checkMapConfiguration()
{
    new const startEntity = getMapEntityData(START_ENTITY);
    new const endEntity = getMapEntityData(END_ENTITY);

    if(!is_valid_ent(startEntity) || !is_valid_ent(endEntity))
    {
        setGameStatus(.status = false);
        return;
    }
}

public initializeGame()
{
    new const startEntity = getMapEntityData(START_ENTITY);
    new const endEntity = getMapEntityData(END_ENTITY);

    log_amx("hP: %d", getMapConfigurationData(TOWER_HEALTH));
}

@releaseMapConfigurationDictionary()
{
    TrieDestroy(g_MapConfigurationKeysTrie);
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
            log_amx("Nie istnieje domyślny plik konfiguracyjny. Gra niemożliwa");
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
    // entity_set_model(towerEntity, GET_MODEL_DIR_FROM_FILE(g_ModelFile[ random(3) ][ MODEL_TOWER ]));

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
        .origin = endSpriteEntityOrigin
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
        .origin = startSpriteEntityOrigin
    );

    setMapEntityData(START_SPRITE_ENTITY, startSpriteEntity);
}

@createCircleSprite(const entityName[], Float:origin[3])
{
    new spriteEntity = create_entity("env_sprite")
    
    entity_set_string(spriteEntity, EV_SZ_classname, entityName)
    // entity_set_model(spriteEntity, SPAWN_SPRITE)
        
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