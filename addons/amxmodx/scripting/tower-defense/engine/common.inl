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

new Array:g_WaveDataArray;
new Trie:g_MonsterTypesConfigurationKeysTrie;

new Trie:g_WavesConfigurationKeysTrie;

new bool:g_IsGamePossible = true;
new bool:g_HasAnyTracks = false;

new g_AliveMonstersNum
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

stock entity_set_aim(ent1, ent2) 
{
	if(!is_valid_ent(ent1) || !is_valid_ent(ent2) || ent1 == ent2)
    {
        return 0;
    }
    
	static Float:offset[3]
	static Float:ent1origin[3]
	static Float:ent2origin[3]
	static Float:view_angles[3]
	
	entity_get_vector(ent2, EV_VEC_origin, ent2origin)
	entity_get_vector(ent1, EV_VEC_origin, ent1origin)
	
	static Float:ent2_angles[3]
	entity_get_vector(ent2, EV_VEC_v_angle, ent2_angles)
	ent2origin[0] += offset[0] * (((floatabs(ent2_angles[1]) - 90) / 90) * -1)
	ent2origin[1] += offset[1] * (1 - (floatabs(90 - floatabs(ent2_angles[1])) / 90))
	
	ent2origin[0] -= ent1origin[0]
	ent2origin[1] -= ent1origin[1]
	
	static Float:hyp
	hyp = floatsqroot( (ent2origin[0] * ent2origin[0]) + (ent2origin[1] * ent2origin[1]))
	
	static x, y, z
	x=0, y=0, z=0
	
	if(ent2origin[0]>=0.0)  x=1
	if(ent2origin[1]>=0.0)  y=1
	
	if(ent2origin[0]==0.0) ent2origin[0] = 0.000001
	if(ent2origin[1]==0.0) ent2origin[1] = 0.000001
	
	ent2origin[0]=floatabs(ent2origin[0])
	ent2origin[1]=floatabs(ent2origin[1])
	
	view_angles[1] = floatatan2(ent2origin[1],ent2origin[0],degrees)
	
	if(x && !y) view_angles[1] = -1 * ( 180 - view_angles[1] )
	if(!x && !y) view_angles[1] = ( 180 - view_angles[1] )
	if(!x && y) view_angles[1] = view_angles[1] = 180 + floatabs(180 - view_angles[1])
	if(x && !y) view_angles[1] = view_angles[1] = 0 - floatabs(-180 - view_angles[1])
	if(!x && !y) view_angles[1] *= -1
	
	while(view_angles[1] > 180.0)  view_angles[1] -= 180
	while(view_angles[1] < -180.0) view_angles[1] += 180

	if(view_angles[1]==180.0 || view_angles[1]==-180.0) view_angles[1]=-179.999999
	
	if(z) view_angles[0] *= -1

	entity_set_int(ent1, EV_INT_fixangle, 1)
	entity_set_vector(ent1, EV_VEC_v_angle, view_angles)
	entity_set_vector(ent1, EV_VEC_angles, view_angles)
	entity_set_int(ent1, EV_INT_fixangle, 1)
	
	return 1;
}
