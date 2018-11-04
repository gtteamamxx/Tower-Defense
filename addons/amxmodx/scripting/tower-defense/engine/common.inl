#if defined td_engine_common_includes
  #endinput
#endif
#define td_engine_common_includes

#define foreach(%1,%2) for( new iCurrentElement = 0 , %2 = %1[ 0 ];  iCurrentElement < sizeof %1 ; iCurrentElement++ , %2 = iCurrentElement < sizeof %1 ? %1[ iCurrentElement ] : 0  )
#define foreach_i(%1,%2,%3) for( new iCurrentElement = 0 , %2 = %1[ 0 ];  iCurrentElement < sizeof %1 ;  %3 = ++iCurrentElement , %2 = iCurrentElement < sizeof %1 ? %1[ iCurrentElement ] : 0 )

new g_MapEntityData[MAP_ENTITIES_ENUM];

new any:g_MapConfiguration[MAP_CONFIGURATION_ENUM];
new Trie:g_MapConfigurationKeysTrie;

new g_Models[MODELS_ENUM][MODELS_CONFIG_PATH_LENGTH];
new Trie:g_ModelsConfigurationKeysTrie;

new bool:g_IsGamePossible = true;

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