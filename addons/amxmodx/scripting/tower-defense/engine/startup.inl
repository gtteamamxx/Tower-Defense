#if defined td_engine_startup_includes
  #endinput
#endif
#define td_engine_startup_includes

public loadMapConfiguration()
{
    new const startEntity = @getStartEntity();
    new const endEntity = @getEndEntity();

    updateMapEntitiesArrayInt(START_ENTITY, startEntity);
    updateMapEntitiesArrayInt(END_ENTITY, endEntity)
}

public checkMapConfiguration()
{
    new const startEntity = getMapEntitiesDataInt(START_ENTITY);
    new const endEntity = getMapEntitiesDataInt(END_ENTITY);

    if(!is_valid_ent(startEntity) || !is_valid_ent(endEntity))
    {
        setGameStatus(.status = false);
        return;
    }
}

public initializeGame()
{
    new const startEntity = getMapEntitiesDataInt(START_ENTITY);
    new const endEntity = getMapEntitiesDataInt(END_ENTITY);
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