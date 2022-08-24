#include <amxmodx>
#include <td>
#include <json>
#include <fakemeta>
#include <fakemeta_util>
#include <engine>
#include <hamsandwich>

#include "tower-defense/engine/counter.inl"
#include "tower-defense/engine/consts.inl"

#define PLUGIN "Tower Defense: Start Zone"
#define VERSION "1.0"
#define AUTHOR "GT Team"

#define START_ZONE_KEY "START_ZONE"
#define START_ZONE_SPRITE "START_ZONE_SPRITE"
#define START_ZONE_CLASS_NAME "startzone"
#define EV_INT_startzone_sprite_entity EV_INT_iuser1
#define STAY_TIME 10
#define STAY_ZONE_HUD_TASK_ID 9992

new Float:g_StartZoneCoordinations[3][3];

new g_StartZoneEntity;
new g_SpriteWhiteLine;

new Array:g_PlayersInStartZoneArray;

new g_AreRequiredNumberOfPlayersCountInStartZone;

new g_LeftTime = STAY_TIME;
new g_StartZoneSpritePath[128];

public plugin_init() 
{
    register_plugin(PLUGIN, VERSION, AUTHOR);

    register_think(START_ZONE_CLASS_NAME, "startZoneThink");

    register_touch(START_ZONE_CLASS_NAME, "player", "startZoneTouched");

    RegisterHamPlayer(Ham_Killed, "onPlayerKilled", 1);

    g_PlayersInStartZoneArray = ArrayCreate();

    initCounterTrie();
}

public plugin_precache()
{
    loadModelsConfiguration();

    g_SpriteWhiteLine = precache_model("sprites/white.spr");

    if (strlen(g_StartZoneSpritePath) > 0)
    {
        precache_model(g_StartZoneSpritePath);
    }
}

public plugin_end()
{
    ArrayDestroy(g_PlayersInStartZoneArray);

    @removeCurrentStartZone();

    destroyCounterTrie();
}

public onPlayerKilled(id)
{
    @setIsPlayerInStartZone(id, .value = false);
}

public client_disconnected(id)
{
    @setIsPlayerInStartZone(id, .value = false);
}

public loadModelsConfiguration()
{
    new configurationFilePath[128];
    formatex(configurationFilePath, 127, "%s/%s.json", CONFIG_DIRECTORY, MODELS_CONFIG_FILE);

    log_amx("[START ZONE] Loading startzone models from file: %s", configurationFilePath);

    new JSON:json = json_parse(configurationFilePath, .is_file = true, .with_comments = true);

    if(!json_is_object(json))
    {
        log_amx("[START ZONE] Models file is not valid JSON file");
        return;
    }

    new JSON:startZoneModelsKeyJson = json_object_get_value(json, START_ZONE_KEY);
    if (startZoneModelsKeyJson == Invalid_JSON)
    {
        log_amx("[START ZONE] No %s key", START_ZONE_KEY);
        return;
    }

    if(!json_object_get_string(startZoneModelsKeyJson, START_ZONE_SPRITE, g_StartZoneSpritePath, charsmax(g_StartZoneSpritePath)))
    {
        log_amx("[START ZONE] %s not found in %s", START_ZONE_SPRITE, configurationFilePath);
        return;
    }
    json_free(startZoneModelsKeyJson);
    json_free(json);
}

public td_on_configuration_load(configurationFilePath[128], bool:isGamePossible)
{
    if (!isGamePossible)
    {
        return;
    }

    log_amx("[START ZONE] Loading startzone from file: %s", configurationFilePath);

    new JSON:json = json_parse(configurationFilePath, .is_file = true, .with_comments = true);

    if(!json_is_object(json))
    {
        log_amx("[START ZONE] File is not valid JSON file");
        return;
    }

    new startZoneCoordinates[128]
    if(!json_object_get_string(json, START_ZONE_KEY, startZoneCoordinates, charsmax(startZoneCoordinates)))
    {
        log_amx("[START ZONE] Invalid start zone JSON value");
    }
    else
    {            
        @loadStartZoneCoordinates(startZoneCoordinates);

        @createStartZone();

        @startShowingHud();
    }

    json_free(json);
}

public showStartZoneHud()
{
    new numberOfAlivePlayers = @getAlivePlayersNum();
    if (numberOfAlivePlayers == 0)
    {
        @showWaitingForPlayersHud();
        return;
    }
    
    if (!g_AreRequiredNumberOfPlayersCountInStartZone)
    {
        @showHowManyPlayersLeftToStayInStartZoneHud();
    }
    else
    {
        @showHowManySecondsLeftToStayInStartZoneHud();
    }
}

public startZoneThink(ent)
{
    @createStartZoneBox();

    @checkWhichPlayersAreNotInStartZone();

    @checkState();

    set_pev(ent, pev_nextthink, get_gametime() + 1)
}

public startZoneTouched(ent, id)
{
    @setIsPlayerInStartZone(id, .value = true);
}

public @setIsPlayerInStartZone(id, bool:value)
{
    new index = ArrayFindValue(g_PlayersInStartZoneArray, id);

    if (index == -1 && value)
    {
        ArrayPushCell(g_PlayersInStartZoneArray, id);
    }
    else if (index != -1 && !value)
    {
        ArrayDeleteItem(g_PlayersInStartZoneArray, index);
    }
}

@showHowManyPlayersLeftToStayInStartZoneHud()
{
    new numberOfRequiredPlayers = @getRequiredNumberOfPlayers();
    new numberOfPlayersInStartZone = @getNumberOfPlayersInStartZone();

    new playersCountLeft = numberOfRequiredPlayers - numberOfPlayersInStartZone;

    // if there's no players left to stay in zone we don't want to show "0 players left..."
    if (playersCountLeft == 0) 
    {
        return;
    }

    set_hudmessage(255, 255, 0, 0.06, 0.63, 1, 1.0, 1.1, 0.2, 0.2, 3)
    show_hudmessage(0, "%d %s left to start game. Please go to start zone...", playersCountLeft, playersCountLeft == 1 ? "player" : "players");
}

@showHowManySecondsLeftToStayInStartZoneHud()
{
    set_hudmessage(0, 255, 0, 0.06, 0.63, 1, 1.0, 1.1, 0.2, 0.2, 3)
    show_hudmessage(0, "Stay yet %d %s in start zone...^nTower Defense created by %s", g_LeftTime, g_LeftTime == 1 ? "second" : "seconds",  AUTHOR);
}

@startShowingHud()
{
    set_task(1.0, "showStartZoneHud", STAY_ZONE_HUD_TASK_ID, .flags = "b");
}

@showWaitingForPlayersHud()
{
    set_hudmessage(255, 0, 0, 0.06, 0.63, 1, 1.0, 1.1, 0.2, 0.2, 3)
    show_hudmessage(0, "Waiting for players...!");
}

@checkWhichPlayersAreNotInStartZone()
{
    new Array:playersInStartZoneArray = ArrayClone(g_PlayersInStartZoneArray);

    for(new i = 0; i < ArraySize(playersInStartZoneArray); ++i)
    {
        new id = ArrayGetCell(playersInStartZoneArray, id);

        new entlist[2];
        if(!find_sphere_class(id, START_ZONE_CLASS_NAME, 1.0 , entlist, 1))
        {
            @setIsPlayerInStartZone(id, .value = false);
        }
    }

    ArrayDestroy(playersInStartZoneArray);
}

@loadStartZoneCoordinates(startZoneCoordinates[128])
{    
    new data[9][16];

    parse(
        startZoneCoordinates, 
        data[0], 15, 
        data[1], 15, 
        data[2], 15, 
        data[3], 15,
        data[4], 15,
        data[5], 15,
        data[6], 15,
        data[7], 15,
        data[8], 15
    );

    for(new i = 0; i < 3 ; ++i)
    {
        g_StartZoneCoordinations[0][i] = str_to_float(data[i]); // origin
        g_StartZoneCoordinations[1][i] = str_to_float(data[i+3]); // mins
        g_StartZoneCoordinations[2][i] = str_to_float(data[i+6]); // max
    }

    log_amx("[START ZONE] Start zone origin: %0.1f %0.1f %0.1f %0.1f %0.1f %0.1f %0.1f %0.1f", 
        g_StartZoneCoordinations[0][0],
        g_StartZoneCoordinations[0][1],
        g_StartZoneCoordinations[0][2],
        g_StartZoneCoordinations[1][0],
        g_StartZoneCoordinations[1][1],
        g_StartZoneCoordinations[1][2],
        g_StartZoneCoordinations[2][0],
        g_StartZoneCoordinations[2][1],
        g_StartZoneCoordinations[2][2]
    );
}

@checkState()
{
    new numberOfRequiredPlayers = @getRequiredNumberOfPlayers();
    new numberOfPlayersInStartZone = @getNumberOfPlayersInStartZone();

    if (numberOfPlayersInStartZone >= numberOfRequiredPlayers && numberOfRequiredPlayers != 0)
    {
        g_AreRequiredNumberOfPlayersCountInStartZone = true;

        if (!isCounterExists(START_ZONE_KEY))
        {
            g_LeftTime = STAY_TIME;
            createCounter(STAY_TIME, START_ZONE_KEY, "startZoneStaySecondElapsed", "onStartZoneTimeElapsed");
        }
    }
    else 
    {
        g_AreRequiredNumberOfPlayersCountInStartZone = false;

        if (isCounterExists(START_ZONE_KEY))
        {
            removeCounter(START_ZONE_KEY);
        }
    }
}

public startZoneStaySecondElapsed(time)
{
    g_LeftTime = time - 1;
}

public onStartZoneTimeElapsed()
{
    @removeCurrentStartZone();
    @stopShowingHud();

    td_start_game();
}

@createStartZoneSpriteEntity()
{
    new ent = create_entity("env_sprite");

    new Float:fOrigin[3];
    fOrigin[0] = g_StartZoneCoordinations[0][0];
    fOrigin[1] = g_StartZoneCoordinations[0][1];
    fOrigin[2] = g_StartZoneCoordinations[0][2] + 55.0; // sprite just above start zone

    entity_set_vector(ent, EV_VEC_origin, fOrigin);
    entity_set_model(ent, g_StartZoneSpritePath);
    entity_set_float(ent, EV_FL_scale, 0.45);

    fm_set_rendering(ent, kRenderFxNone, 0, 0, 0, kRenderTransAdd, 255);

    return ent;
}

@setStartZoneSprite(ent)
{
    entity_set_int(g_StartZoneEntity, EV_INT_startzone_sprite_entity, ent);
}

@getNumberOfPlayersInStartZone()
{
    return ArraySize(g_PlayersInStartZoneArray);
}

@createStartZone()
{
    @removeCurrentStartZone();

    g_StartZoneEntity = @createStartZoneEntity();

    new sprite = @createStartZoneSpriteEntity();

    @setStartZoneSprite(sprite);

    @createStartZoneBox();

    set_pev(g_StartZoneEntity, pev_nextthink, get_gametime() + 1);
}

@createStartZoneEntity()
{
    new ent = create_entity("trigger_multiple");

    entity_set_string(ent, EV_SZ_classname, START_ZONE_CLASS_NAME);

    entity_set_vector(ent, EV_VEC_origin, g_StartZoneCoordinations[0]);

    dllfunc(DLLFunc_Spawn, ent);

    set_pev(ent, pev_solid, SOLID_TRIGGER);

    set_pev(ent, pev_movetype, MOVETYPE_NONE);

    entity_set_size(ent, g_StartZoneCoordinations[1], g_StartZoneCoordinations[2]);

    return ent;
}

@stopShowingHud()
{
    remove_task(STAY_ZONE_HUD_TASK_ID);
}

@removeCurrentStartZone()
{
    if(is_valid_ent(g_StartZoneEntity)) 
    {
        new spriteEnt = entity_get_int(g_StartZoneEntity, EV_INT_startzone_sprite_entity);

        if(is_valid_ent(spriteEnt))
        {
            remove_entity(spriteEnt);
        }

        remove_entity(g_StartZoneEntity);
    }
}

@createStartZoneBox()
{
    new Float:maxs[3], Float:mins[3], Float:fOrigin[3];

    pev(g_StartZoneEntity, pev_absmin, mins);
    pev(g_StartZoneEntity, pev_absmax, maxs);
    pev(g_StartZoneEntity, pev_origin, fOrigin);

    new Float:heightOffset = -5.0;
    new Float:z;
    new num = 4;

    for(new i = 0; i < num; ++i)
    {
        z = fOrigin[2] + heightOffset;

        @drawLine(maxs[0], maxs[1], z, mins[0], maxs[1], z);
        @drawLine(maxs[0], maxs[1], z, maxs[0], mins[1], z);
        @drawLine(maxs[0], mins[1], z, mins[0], mins[1], z);
        @drawLine(mins[0], mins[1], z, mins[0], maxs[1], z);

        heightOffset += 5.0;
    }
}

@drawLine(Float:x1, Float:y1, Float:z1, Float:x2, Float:y2, Float:z2)
{
    new Float:startOrigin[3], Float:stopOrigin[3];
    startOrigin[0] = x1;
    startOrigin[1] = y1;
    startOrigin[2] = z1 - 20.0;

    stopOrigin[0] = x2;
    stopOrigin[1] = y2;
    stopOrigin[2] = z2 - 20.0;

    // green line
    @createLine(startOrigin, stopOrigin, {0, 255, 0});
}

@createLine(Float:startOrigin[], Float:stopOrigin[], color[3])
{
    message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
    write_byte(TE_BEAMPOINTS);
    engfunc(EngFunc_WriteCoord, startOrigin[0]);
    engfunc(EngFunc_WriteCoord, startOrigin[1]);
    engfunc(EngFunc_WriteCoord, startOrigin[2]);
    engfunc(EngFunc_WriteCoord, stopOrigin[0]);
    engfunc(EngFunc_WriteCoord, stopOrigin[1]);
    engfunc(EngFunc_WriteCoord, stopOrigin[2]);
    write_short(g_SpriteWhiteLine);
    write_byte(1);
    write_byte(5);
    write_byte(11);
    write_byte(20);
    write_byte(0);
    write_byte(color[0]);
    write_byte(color[1]);
    write_byte(color[2]);					
    write_byte(250);
    write_byte(5);
    message_end();
}

@getAlivePlayersNum()
{
    new num = 0;
    for(new i = 1 ; i <= get_maxplayers(); ++i)
    {
        if(is_user_alive(i))
            num++;
    }

    return num;
}

@getRequiredNumberOfPlayers()
{
    new result = 0;
    new alivePlayersNum = @getAlivePlayersNum();

    if (alivePlayersNum == 1 || alivePlayersNum== 2) 
    {
        result = alivePlayersNum;
    }
    else
	{
        result = floatround(alivePlayersNum * 0.75, floatround_round)
    }

    return result;
}