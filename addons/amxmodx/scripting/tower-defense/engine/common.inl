#if defined td_engine_common_includes
  #endinput
#endif
#define td_engine_common_includes

#define foreach(%1,%2) for( new iCurrentElement = 0 , %2 = %1[ 0 ];  iCurrentElement < sizeof %1 ; iCurrentElement++ , %2 = iCurrentElement < sizeof %1 ? %1[ iCurrentElement ] : 0  )
#define foreach_i(%1,%2,%3) for( new iCurrentElement = 0 , %2 = %1[ 0 ];  iCurrentElement < sizeof %1 ;  %3 = ++iCurrentElement , %2 = iCurrentElement < sizeof %1 ? %1[ iCurrentElement ] : 0 )

new g_MapEntityData[MAP_ENTITIES_ENUM];
new DataPack:g_MapConfiguration[MAP_CONFIGURATION_ENUM][MAP_CONFIGURATION_DATA_ENUM];

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

stock any:getMapEntityData(MAP_ENTITIES_ENUM:item, Float:vector[] = {}, len = 0)
{
    if(len > 0)
    {
        xs_vec_copy(any:g_MapEntityData[item], vector);
    }

    return g_MapEntityData[item];
}

public getMapConfigDataCell(MAP_CONFIGURATION_ENUM:item)
{
    new const DataPack:dataPack = g_MapConfiguration[item][DATAPACK];
    ResetPack(dataPack);
    return ReadPackCell(dataPack);
}

public Float:getMapConfigDataFloat(MAP_CONFIGURATION_ENUM:item)
{
    new const DataPack:dataPack = g_MapConfiguration[item][DATAPACK];
    ResetPack(dataPack);
    return ReadPackFloat(dataPack);
}

public getMapConfigDataString(MAP_CONFIGURATION_ENUM:item, buffer[], len)
{
    new const DataPack:dataPack = g_MapConfiguration[item][DATAPACK];
    ResetPack(dataPack);
    ReadPackString(dataPack, buffer, len)
}

public setMapConfigDataCell(MAP_CONFIGURATION_ENUM:item, value)
{
    new const DataPack:dataPack = g_MapConfiguration[item][DATAPACK];
    ResetPack(dataPack);
    WritePackCell(dataPack, value);
}

public setMapConfigDataFloat(MAP_CONFIGURATION_ENUM:item, Float:value)
{
    new const DataPack:dataPack = g_MapConfiguration[item][DATAPACK];
    ResetPack(dataPack);
    WritePackFloat(dataPack, value);
}

public setMapConfigDataString(MAP_CONFIGURATION_ENUM:item, value[])
{
    new const DataPack:dataPack = g_MapConfiguration[item][DATAPACK];
    ResetPack(dataPack);
    WritePackString(dataPack, value);
}

public initCommon()
{
    for(new i = 0; i < _:MAP_CONFIGURATION_ENUM; ++i)
    {
        static MAP_CONFIGURATION_ENUM:index; index = MAP_CONFIGURATION_ENUM:i;
        g_MapConfiguration[index][DATAPACK] = CreateDataPack();
        g_MapConfiguration[index][CONFIG_NAME] = any:g_MapConfigurationKeys[index];
    }
}

public freeCommon()
{
    for(new i = 0; i < _:MAP_CONFIGURATION_ENUM; ++i)
    {
        DestroyDataPack(g_MapConfiguration[MAP_CONFIGURATION_ENUM:i][DATAPACK]);
    }
}