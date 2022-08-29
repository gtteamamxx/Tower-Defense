#if defined td_engine_natives_includes
  #endinput
#endif
#define td_engine_natives_includes

public plugin_natives()
{
    register_library("td");
    register_native("td_register_monster", "@_td_register_monster");
    register_native("td_get_monster_entity_name", "@_td_get_monster_entity_name");
    register_native("td_is_monster", "@_td_is_monster");
    register_native("td_is_monster_killed", "@_td_is_monster_killed");
    register_native("entity_set_aim", "@entity_set_aim");
    register_native("td_aim_monster_to_track", "@aimMonsterToTrack");
    register_native("td_stop_monster", "@_td_stop_monster");
    register_native("td_get_monster_actual_track_id", "@_td_get_monster_actual_track_id");
    register_native("td_start_game", "@_td_start_game");
    register_native("td_get_monsters_in_sphere", "@_td_get_monsters_in_sphere");
    register_native("td_take_monster_damage", "@_td_take_monster_damage");
}

@_td_stop_monster(pluginId, argc)
{
    new monsterEntity = get_param(1);

    if (!isMonster(monsterEntity)) 
    {
        return;
    }

    entity_set_vector(monsterEntity, EV_VEC_velocity, Float:{0.0, 0.0, 0.0});
}

@_td_get_monster_actual_track_id(monsterEntity)
{
    new actualMonsterTrack; CED_GetCell(monsterEntity, MONSTER_DATA_TRACK_KEY, actualMonsterTrack);
    return actualMonsterTrack;
}

@_td_get_monsters_in_sphere(pluginId, argc)
{
    new ent = get_param(1);
    new Float:distance = get_param_f(2);
    new len = get_param(4);
    
    // if no monsters then no need to calculate
    new monstersNum = getMonstersNumberOnMap();
    if (monstersNum == 0)
    {
        return 0;
    }

    static monsters[64]
    new monstersInDistanceNum;
    for(new i = 0; i < monstersNum; ++i)
    {
        new monsterEntity = ArrayGetCell(g_MonstersEntArray, i);
        if (isMonsterKilled(monsterEntity)) continue;

        new Float:entityDistance = entity_range(ent, monsterEntity);
        if (entityDistance <= distance)
        {
            monsters[monstersInDistanceNum++] = monsterEntity;

            if (monstersInDistanceNum == len) break;
        }
    }

    set_string(3, monsters, len);

    return monstersInDistanceNum;
}

public @aimMonsterToTrack(pluginId, argc)
{
    new monsterEntity = get_param(1);
    new trackEntity = get_param(2);

    aimMonsterToTrack(monsterEntity, trackEntity);
}

@entity_set_aim(pluginId, argc) 
{
    new ent1 = get_param(1);
    new ent2 = get_param(2);

    entity_set_aim(ent1, ent2);
}

bool:@_td_is_monster(pluginId, argc)
{
    new monsterEntity = get_param(1);
    return isMonster(monsterEntity);
}

bool:@_td_is_monster_killed(pluginId, argc)
{
    new monsterEntity = get_param(1);
    return isMonsterKilled(monsterEntity);
}

/*
    Params count - minimum 2
    Param 1 - string[33] - Monster type name
    Param 2 - X string[128] - Path to monster model
*/
bool:@_td_register_monster(pluginId, argc)
{
    if(argc < 2) 
    {
        log_amx("Bad use of _td_register_monster by plugin %d. Arguments passed %d/2 needed", pluginId, argc);
        return false;
    }

    new Array:monsterModelsArray = ArrayCreate(128);
    new monsterTypeKey[33];

    get_string(1, monsterTypeKey, charsmax(monsterTypeKey));

    for(new i = 2; i <= argc; ++i)
    {
        new model[128];
        get_string(i, model, charsmax(model));
        ArrayPushString(monsterModelsArray, model);
    }

    register_monster(pluginId, monsterTypeKey, monsterModelsArray)

    return true;
}

// param 1 - player
// param 2 - monster
// param 3 - damage
// param 4 - damage bit

@_td_take_monster_damage(pluginId, argc)
{
    if (argc < 4)
    {
        log_amx("Bad use of _td_take_monster_damage");
        return;
    }

    new id = get_param(1);
    new monster = get_param(2);
    new Float:damage = get_param_f(3);
    new damageBit = get_param(4);

    ExecuteHamB(Ham_TakeDamage, monster, id, id, damage, damageBit, 1);
}

/*
    Params count: 3
    Param 1 string[33] - Monster type name
    Param 2 string[] - buffer
    Param 3 int - buffer len
*/

@_td_get_monster_entity_name(pluginId, argc)
{
    if(argc != 3)
    {
        log_amx("Bad use of _td_get_monster_entity_name");
        return;
    }

    new monsterEntityName[64]
    get_string(1, monsterEntityName, charsmax(monsterEntityName));
    
    getMonsterClassName(monsterEntityName, .monsterTypeName = monsterEntityName);

    set_string(2, monsterEntityName, get_param(3));
}

@_td_start_game()
{
    startGame();
}