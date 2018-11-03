#if defined td_engine_startup_includes
  #endinput
#endif
#define td_engine_startup_includes

public loadMapConfiguration()
{
    @loadMapConfigurationFromConfigurationFile();

    new const startEntity = @getStartEntity();
    new const endEntity = @getEndEntity();

    setMapEntityData(START_ENTITY, startEntity);
    setMapEntityData(END_ENTITY, endEntity);
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