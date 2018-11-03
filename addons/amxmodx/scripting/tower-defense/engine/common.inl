#if defined td_engine_common_includes
  #endinput
#endif
#define td_engine_common_includes

#define foreach(%1,%2) for( new iCurrentElement = 0 , %2 = %1[ 0 ];  iCurrentElement < sizeof %1 ; iCurrentElement++ , %2 = iCurrentElement < sizeof %1 ? %1[ iCurrentElement ] : 0  )
#define foreach_i(%1,%2,%3) for( new iCurrentElement = 0 , %2 = %1[ 0 ];  iCurrentElement < sizeof %1 ;  %3 = ++iCurrentElement , %2 = iCurrentElement < sizeof %1 ? %1[ iCurrentElement ] : 0 )

new Array:g_MapEntitiesArray;

new bool:g_IsGamePossible = true;

public setGameStatus(bool:status) 
{
    g_IsGamePossible = status;
}

public bool:getGameStatus()
{
    return g_IsGamePossible;
}

public getMapEntitiesDataInt(MAP_ENTITIES_ENUM:item)
{
    return ArrayGetCell(g_MapEntitiesArray, _:item);
}

public getMapEntitiesDataVector(MAP_ENTITIES_ENUM:item, output[])
{
    return ArrayGetArray(g_MapEntitiesArray, _:item, output);
}

public updateMapEntitiesArrayInt(MAP_ENTITIES_ENUM:item, value)
{
    ArrayInsertCellAfter(g_MapEntitiesArray, _:item, value);
}

public updateMapEntitiesArrayVector(MAP_ENTITIES_ENUM:item, Float:value[])
{
    ArrayInsertArrayAfter(g_MapEntitiesArray, _:item, value);
}