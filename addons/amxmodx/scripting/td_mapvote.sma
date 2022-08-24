#include <amxmodx>
#include <amxmisc>
#include <td>
#include <json>
#include <fakemeta_util>
#include <engine>

#include "tower-defense/engine/counter.inl"
#include "tower-defense/engine/consts.inl"

#define PLUGIN "Tower Defense: Map Vote"
#define VERSION "1.0"
#define AUTHOR "GT Team"

#define LAST_MAPS_PLAYED_FILE_PATH "addons/amxmodx/data/td-lastmapsplayed.cfg"
#define TD_MAPS_CONFIG_FILE_NAME "td_maps.cfg"

#define MAPVOTE_CLASSNAME "mapvote"
#define RESTART_MAP_NAME "restart"

#define MAP_VOTE_ZONE_KEY "MAP_VOTE_ZONE"
#define VOTE_ZONE_SPRITE "VOTE_ZONE_SPRITE"

#define MAP_VOTE_ZONE_1_KEY "MAP_VOTE_ZONE_1"
#define MAP_VOTE_ZONE_2_KEY "MAP_VOTE_ZONE_2"
#define MAP_VOTE_ZONE_3_KEY "MAP_VOTE_ZONE_3"

#define EV_INT_mapvote_header EV_INT_iuser1
#define EV_INT_mapvote_index EV_INT_iuser2

#define NUMBER_OF_MAPS_TO_STORE_AS_LAST_PLAYED 1

#define MAP_VOTE_TIME 20
#define CHANGE_MAP_DELAY_TIME 10

new g_SpriteWhiteLine;

new Float:g_MapVoteZoneCoordinations[3][3][3];
new g_MapVoteZoneEntity[3];
new Array:g_PlayersInMapVoteZoneArray;
new Array:g_NextMapNamesArray;

new g_MapVoteSpritePath[128];

public plugin_init() 
{
    register_plugin(PLUGIN, VERSION, AUTHOR)

    register_think(MAPVOTE_CLASSNAME, "mapVoteZoneThink");

    initCounterTrie();
}

public plugin_end()
{
    destroyCounterTrie();

    @removeAllMapVoteEntities();

    @clearArrays();

    @saveMapNameAsLastPlayed();
}

public plugin_precache()
{
    loadModelsConfiguration();

    precache_model(g_MapVoteSpritePath);

    g_SpriteWhiteLine = precache_model("sprites/white.spr");
}

public td_on_configuration_load(configurationFilePath[128], bool:isGamePossible)
{
    if (!isGamePossible)
    {
        return;
    }

    log_amx("[START ZONE] Loading mapvote from file: %s", configurationFilePath);

    new JSON:json = json_parse(configurationFilePath, .is_file = true, .with_comments = true);

    if(!json_is_object(json))
    {
        log_amx("[START ZONE] File is not valid JSON file");
        return;
    }

    new mapVoteZoneCoordinates[3][128];
    if(!json_object_get_string(json, MAP_VOTE_ZONE_1_KEY, mapVoteZoneCoordinates[0], 127)
        || !json_object_get_string(json, MAP_VOTE_ZONE_2_KEY, mapVoteZoneCoordinates[1], 127)
        || !json_object_get_string(json, MAP_VOTE_ZONE_3_KEY, mapVoteZoneCoordinates[2], 127))
    {
        log_amx("[START ZONE] Invalid start zone JSON value.");
    }
    else
    {            
        @loadMapVoteZoneCoordinates(mapVoteZoneCoordinates);
    }

    json_free(json);
}

public td_on_game_end()
{
    createCounter(
        10,
        "map_vote_zone_fx",
        "@prepareToVoteTimeLeft",
        "@startMapVote"
    );
}

public mapVoteZoneThink(ent)
{
    new mapVoteIndex = entity_get_int(ent, EV_INT_mapvote_index);

    @loadPlayersInVoteZone(ent, mapVoteIndex);

    @drawVoteZone(ent);
    
    set_pev(ent, pev_nextthink, get_gametime() + 1);
}

public loadModelsConfiguration()
{
    new configurationFilePath[128];
    formatex(configurationFilePath, 127, "%s/%s.json", CONFIG_DIRECTORY, MODELS_CONFIG_FILE);

    log_amx("[MAP VOTE ZONE] Loading votezone models from file: %s", configurationFilePath);

    new JSON:json = json_parse(configurationFilePath, .is_file = true, .with_comments = true);

    if(!json_is_object(json))
    {
        log_amx("[MAP VOTE ZONE] Models file is not valid JSON file");
        return;
    }

    new JSON:mapVoteZoneModelsKeyJson = json_object_get_value(json, MAP_VOTE_ZONE_KEY);
    if (mapVoteZoneModelsKeyJson == Invalid_JSON)
    {
        log_amx("[MAP VOTE ZONE] No %s key", MAP_VOTE_ZONE_KEY);
        return;
    }

    if(!json_object_get_string(mapVoteZoneModelsKeyJson, VOTE_ZONE_SPRITE, g_MapVoteSpritePath, charsmax(g_MapVoteSpritePath)))
    {
        log_amx("[MAP VOTE ZONE] %s not found in %s", VOTE_ZONE_SPRITE, configurationFilePath);
        return;
    }

    json_free(mapVoteZoneModelsKeyJson);
    json_free(json);
}

@loadPlayersInVoteZone(ent, mapVoteIndex)
{
    // get map vote array
    new Array:mapVoteArray = Array:ArrayGetCell(g_PlayersInMapVoteZoneArray, mapVoteIndex - 1);

    new players[MAX_PLAYERS]; 

    // because all map vote zones are quadratic we can safely
    // get mins[0] - the X offset to get the distance of the radius
    
    new Float:radius = floatabs(g_MapVoteZoneCoordinations[mapVoteIndex - 1][1][0]);

    // find all players standing in vote zone
    new playersInVoteZone = find_sphere_class(ent, "player", radius, players, charsmax(players));
    
    // clear all players in vote zone
    ArrayClear(mapVoteArray);

    for(new i = 0; i < playersInVoteZone; ++i)
    {
        new playerId = players[i];

        // if player is in vote zone and is alive
        if (is_user_alive(playerId))
        {   
            // add player id to array
            ArrayPushCell(mapVoteArray, playerId);
        }
    }
}

@saveMapNameAsLastPlayed()
{
    new Array:lastPlayedMapsArray = Array:ArrayCreate(.cellsize = 64);

    /* Load all last played maps */
    if(file_exists(LAST_MAPS_PLAYED_FILE_PATH))
    {
        new lineText[64], len;

        for(new i; read_file(LAST_MAPS_PLAYED_FILE_PATH, i, lineText, 63, len) ; i++) 
        {
            trim(lineText)
            
            /* If its empty line then load next */
            if(!strlen(lineText)) continue;
            
            /* Remove "" */
            remove_quotes(lineText)
            ArrayPushString(lastPlayedMapsArray, lineText);
        }
    }

    new currentMap[33];
    get_mapname(currentMap, 32);

    log_amx("Map %s added to td-lastmapsplayed.cfg.", currentMap)
        
    write_file(LAST_MAPS_PLAYED_FILE_PATH, currentMap, 0);

    for(new i = 1; i < NUMBER_OF_MAPS_TO_STORE_AS_LAST_PLAYED ; i++)
    {
        new lastPlayedMapName[64];
        ArrayGetString(lastPlayedMapsArray, i, lastPlayedMapName, 63);

        write_file(LAST_MAPS_PLAYED_FILE_PATH, lastPlayedMapName, i);
    }

    ArrayDestroy(lastPlayedMapsArray);
}

@drawVoteZone(ent)
{
    static Float:maxs[3], Float:mins[3];
    pev(ent, pev_absmax, maxs);
    pev(ent, pev_absmin, mins);

    static Float:fOrigin[3];
    pev(ent, pev_origin, fOrigin);

    new Float:fOff = -5.0;
    new Float:z;
    for(new i=0;i < 3; i++)
    {
        z = fOrigin[2]+fOff;
        @drawVoteMapLine(maxs[0], maxs[1], z, mins[0], maxs[1], z);
        @drawVoteMapLine(maxs[0], maxs[1], z, maxs[0], mins[1], z);
        @drawVoteMapLine(maxs[0], mins[1], z, mins[0], mins[1], z);
        @drawVoteMapLine(mins[0], mins[1], z, mins[0], maxs[1], z);
        fOff += 5.0;
    }
}

@loadMapVoteZoneCoordinates(startZoneCoordinates[3][128])
{
    new data[9][16];

    for(new i = 0; i < 3; ++i)
    {
        parse(
            startZoneCoordinates[i], 
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

        for(new j = 0; j < 3 ; ++j)
        {
            g_MapVoteZoneCoordinations[i][0][j] = str_to_float(data[j]); // origin
            g_MapVoteZoneCoordinations[i][1][j] = str_to_float(data[j+3]); // mins
            g_MapVoteZoneCoordinations[i][2][j] = str_to_float(data[j+6]); // max
        }

        log_amx("[START ZONE] Map vote zone %d origins: %0.1f %0.1f %0.1f %0.1f %0.1f %0.1f %0.1f %0.1f",
            i + 1, 
            g_MapVoteZoneCoordinations[i][0][0],
            g_MapVoteZoneCoordinations[i][0][1],
            g_MapVoteZoneCoordinations[i][0][2],
            g_MapVoteZoneCoordinations[i][1][0],
            g_MapVoteZoneCoordinations[i][1][1],
            g_MapVoteZoneCoordinations[i][1][2],
            g_MapVoteZoneCoordinations[i][2][0],
            g_MapVoteZoneCoordinations[i][2][1],
            g_MapVoteZoneCoordinations[i][2][2]
        );
    }
}

@startMapVote()
{
    @emitTimeToChooseSound();

    // when vote start we need to load maps to vote
    @loadNextMapNames();

    // then we're initiating arrays where'll be stored players who are in vote zone
    @initPlayersInVoteZoneArrays();

    // then we create vote zone entities
    @createMapVoteZones();

    // then we start counting down to te vote
    @startVoteCounter();
}

@startVoteCounter()
{
    createCounter(
        MAP_VOTE_TIME, 
        MAP_VOTE_ZONE_KEY, 
        "@onMapVoteTimeLeftChanged", 
        "@onMapVoteFinish"
    );
}

@onMapVoteTimeLeftChanged(time)
{
    // during vote we are showing how much time left
    set_hudmessage(255, 0, 0, 0.2, 0.49, 0, 1.0, 1.1)
    show_hudmessage(0, "Vote will finish in %d %s", time, time == 1 ? "second" : "seconds");

    // and also we are showing menu for all players
    @showAllPlayersMenuWithMaps(time)
}

@showAllPlayersMenuWithMaps(timeLeft)
{
    new menu = menu_create("\yMap in votes:", "@blankCb");

    new numberOfAllVotes = @getNumberOfPlayersInAllVoteZones();
    new numberOfMapsInVote = ArraySize(g_NextMapNamesArray);
    new numberOfPlayersNotInVoteZone = @getAlivePlayersNum() - numberOfAllVotes;

    // we iterate through all maps in vote
    for(new i = 0; i < numberOfMapsInVote; ++i)
    {
        new menuItemDescription[128];
        new numberOfPlayersInVoteZone = @getNumberOfPlayersInVoteZone(i + 1);

        // we get map name to vote
        new mapName[64];
        ArrayGetString(g_NextMapNamesArray, i, mapName, 63);

        // if map name is restart map then we change "restart" to something more alphabetical
        if (equali(mapName, RESTART_MAP_NAME)) 
        {
            formatex(mapName, 128, "Restart Map");
        }

        formatex(menuItemDescription, 127, "MAP:\r %s\w | %d %s", mapName, numberOfPlayersInVoteZone, numberOfPlayersInVoteZone == 1 ? "vote" : "votes");
        
        //if this is last menu item add extra description
        if (i == (numberOfMapsInVote - 1))
        {
            if(numberOfPlayersNotInVoteZone > 0)
            {
                format(menuItemDescription, 127, "%s^n^n\r%d %s\w didn't voted yet.^n\wEnding vote in: \r%d %s", menuItemDescription, 
                    numberOfPlayersNotInVoteZone, numberOfPlayersNotInVoteZone == 1 ? "player" : "players",
                    timeLeft, timeLeft == 1 ? "second" : "seconds"
                );
            }
            else
            {
                format(menuItemDescription, 127, "%s^n^n\rAll players have voted.^n\wEnding vote in: \r%d %s", menuItemDescription, 
                    timeLeft, timeLeft == 1 ? "second" : "seconds"
                );
            }

        }
            
        menu_additem(menu, menuItemDescription);
    }

    for(new i = 1 ; i <= get_maxplayers(); i ++)
    {
        if(is_user_connected(i)) 
        {
            menu_display(i, menu);
        }
    }
}

@getNumberOfPlayersInAllVoteZones()
{
    new numberOfVoteZones = ArraySize(g_NextMapNamesArray);

    new result = 0;

    for(new i = 0; i < numberOfVoteZones; ++i)
    {
        result += @getNumberOfPlayersInVoteZone(i + 1);
    }

    return result;
}

@getNumberOfPlayersInVoteZone(voteZoneIndex)
{
    new Array:playersInVoteZoneArray = Array:ArrayGetCell(g_PlayersInMapVoteZoneArray, voteZoneIndex - 1);

    return ArraySize(playersInVoteZoneArray);
}

@blankCb(id, menu, item) 
{ 
    menu_destroy(menu);
    return PLUGIN_HANDLED;
}

@onMapVoteFinish()
{
    // show some hud information
    set_hudmessage(255, 0, 0, 0.2, 0.49, 0, 1.0, 5.0)
    show_hudmessage(0, "Vote has been finished!^nCalculating results...");

    // remove all map vote zone entities
    @removeAllMapVoteEntities();

    // calculate map winner
    new winnerMapIndex = @getMapWinnerIndex();

    new parameter[1];
    parameter[0] = winnerMapIndex;

    createCounter(
        CHANGE_MAP_DELAY_TIME,
        "map_vote_zone_change_map",
        "@changeMapTimeLeft",
        "@changeMap",
        .delay = 5.0,
        .customInfo = winnerMapIndex
    );
}

@changeMap(winnerMapIndex)
{
    new mapName[64];
    ArrayGetString(g_NextMapNamesArray, winnerMapIndex, mapName, 63);

    @clearArrays();

    set_task(0.1, "@changeLevel", .parameter = mapName, .len = 63);
}

@changeLevel(mapName[64])
{
    if(containi(mapName, RESTART_MAP_NAME) != -1)
    {
        get_mapname(mapName, charsmax(mapName))
    }

    server_cmd("changelevel %s", mapName);
}

@clearArrays()
{
    if (g_NextMapNamesArray == Invalid_Array) 
    {
        return;
    }

    new mapsCount = ArraySize(g_NextMapNamesArray);

    for(new i = 0; i < mapsCount; ++i) 
    {
        new Array:playersArray = ArrayGetCell(g_PlayersInMapVoteZoneArray, i);
        ArrayDestroy(playersArray);
    }

    ArrayDestroy(g_PlayersInMapVoteZoneArray);
    ArrayDestroy(g_NextMapNamesArray);
}

@changeMapTimeLeft(time, winnerMapIndex)
{
    new mapName[64];
    ArrayGetString(g_NextMapNamesArray, winnerMapIndex, mapName, 63);

    set_hudmessage(255, 0, 0, 0.2, 0.49, 0, 1.0, 1.0)

    // if it's restart then display other text
    if(equali(mapName, RESTART_MAP_NAME)) 
    {
        show_hudmessage(0, "Restarting map in %d %s", time, time == 1 ? "second" : "seconds");
    }
    else
    {
        show_hudmessage(0, "Change to map %s in %d %s", mapName, time, time == 1 ? "second" : "seconds");
    }

    if (time <= 10)
    {
        @speakFx(time);
    }
}

@getMapWinnerIndex()
{
    new Array:votesCountArray = ArrayCreate();
    new mapsCount = ArraySize(g_NextMapNamesArray);
    
    // first we save number of votes to an array
    for(new i = 0; i < mapsCount; ++i)
    {
        new numberOfVotes = @getNumberOfPlayersInVoteZone(i + 1);
        ArrayPushCell(votesCountArray, numberOfVotes);
    }

    // then we calculate winner 
    new mostVotes, index;
    for (new i = 0; i < mapsCount; i++)
    {
        new votes = ArrayGetCell(votesCountArray, i);
        if(votes > mostVotes)
        {
            mostVotes = votes;
            index = i;
        }
    }

    ArrayDestroy(votesCountArray);

    return index;
}

@prepareToVoteTimeLeft(time)
{
    set_hudmessage(255, 0, 0, 0.2, 0.49, 0, 1.0, 1.1)
    show_hudmessage(0, "Get ready to vote map in %d %s", time, time == 1 ? "second" : "seconds");

    if(time <= 6) 
    {
        @speakFx(time);
    }
}

@emitTimeToChooseSound()
{
	client_cmd(0, "spk Gman/Gman_Choose%d", random_num(1, 2));
}

@speakFx(time)
{
    new word[6];
    num_to_word(time, word, 5);

    client_cmd(0, "spk ^"fvox/%s^"", word);
}

@fillNextMapsArrayWithMapsFromConfigurationFile()
{
    new mapsFilePath[128];
    formatex(mapsFilePath, 127, "%s/%s", CONFIG_DIRECTORY, TD_MAPS_CONFIG_FILE_NAME);

    log_amx("Loading maps to vote from file %s", mapsFilePath);

    // save create copy of array with all previously played maps
    new Array:lastPlayedMapsArray = ArrayClone(g_NextMapNamesArray);

    // clear next map array to load all maps to new array
    ArrayClear(g_NextMapNamesArray);

    // check if file exists
    if(file_exists(mapsFilePath))
    {
        new line[64], len;

        // read all file and fill array
        for(new i = 0; read_file(mapsFilePath, i, line, 64, len); ++i)
        {
            trim(line);
            remove_quotes(line);
            
            if(line[0] == ';' || !line[0])
                continue

            log_amx("Loaded map to vote: %s.", line)
            
            // add loaded map to an array
            ArrayPushString(g_NextMapNamesArray, line);
        }
    }

    // check if last played map is in array
    // if it's not it means it should not be played
    // for example
    // last played map 
    // 1. as_oilrig
    // maps in config file: 
    // 1. td_night
    // 2. td_empire
    // it means we can't hold as_oilrig because it's not in config file
    new lastPlayedMapsCount = ArraySize(lastPlayedMapsArray);

    // loop through all last maps played
    for(new i = 0; i < lastPlayedMapsCount; ++i)
    {
        // get last played map name
        new mapName[64];
        ArrayGetString(lastPlayedMapsArray, i, mapName, 63);

        // check if map name is present in configuration maps
        // if true then we can assume this was previously played map
        // so it means we can't play vote for it
        if (ArrayFindString(g_NextMapNamesArray, mapName) != -1)
        {
            // add same map name to next maps array
            // and make it duplicate
            // so the next logic will remove duplications
            ArrayPushString(g_NextMapNamesArray, mapName);
        }
    }

    // destroy last played maps array
    // because we won't use it 
    ArrayDestroy(lastPlayedMapsArray);
}

@removeDuplicateEntriesFromNextMapArrays()
{
    // if there's only one map we don't do anytinh
    if (ArraySize(g_NextMapNamesArray) == 1)
    {
        return;
    }

    // before duplication we're creating array clone
    new Array:mapsArray = ArrayCreate(64);

    for(new i = 0; i < ArraySize(g_NextMapNamesArray); ++i)
    {
        // we get map name
        new mapName[64];
        ArrayGetString(g_NextMapNamesArray, i, mapName, 63);

        // if it's unique map we can add it
        if (ArrayFindString(mapsArray, mapName) == -1)
        {
            ArrayPushString(mapsArray, mapName);
        }
    }

    // we can safly destroy duplicated array
    ArrayDestroy(g_NextMapNamesArray)

    // and set up new array without duplicated maps
    g_NextMapNamesArray = mapsArray;
}

@randomlySetNextMaps()
{
    new mapsCount = ArraySize(g_NextMapNamesArray);

    // if there is only one or two maps in array
    // we don't have to randomize collection due
    // alway same results
    if (mapsCount <= 2)
    {
        return;
    }

    // we're randomly selecting first map
    new firstMapIndex = random(mapsCount);

    new secondMapIndex = 0;
    // then we're randomly selecting second map
    // as long as same as first one
    do
    {
        secondMapIndex = random(mapsCount);
    } while (firstMapIndex == secondMapIndex)
    
    // as we have first map and second map randomly selected
    // we can setup new next maps array
    new Array:newMapsArray = ArrayCreate(.cellsize = 64);

    new mapNames[2][64];
    ArrayGetString(g_NextMapNamesArray, firstMapIndex, mapNames[0], 63);
    ArrayGetString(g_NextMapNamesArray, secondMapIndex, mapNames[1], 63);

    ArrayPushString(newMapsArray, mapNames[0]);
    ArrayPushString(newMapsArray, mapNames[1]);

    // when we have filled new maps array we can free previous one and set up a new one
    ArrayDestroy(g_NextMapNamesArray);
    
    g_NextMapNamesArray = newMapsArray;
}

@loadNextMapNames()
{
    g_NextMapNamesArray = ArrayCreate(.cellsize = 64);

    // we fill next maps array with previous maps to know which map we can't vote
    @fillNextMapsArrayWithPreviousMaps();

    // then we fill next maps array with all maps from config file
    @fillNextMapsArrayWithMapsFromConfigurationFile();

    // then we remove duplicate entries
    @removeDuplicateEntriesFromNextMapArrays();

    // then we don't need current map in next map arrays
    @removeCurrentMapFromNextMapArrays();

    // then we can randomly select next maps in array
    @randomlySetNextMaps();

    // then we can add restart
    @addRestartMapToNextMap();
}

@addRestartMapToNextMap()
{
    ArrayPushString(g_NextMapNamesArray, RESTART_MAP_NAME);
}

@removeCurrentMapFromNextMapArrays()
{
    // first get current map name
    new currentMap[64];
    get_mapname(currentMap, 63);

    // then get current map index in array
    new currentMapIndex = ArrayFindString(g_NextMapNamesArray, currentMap);
    
    // if current map is present
    if (currentMapIndex != -1)
    {
        // remove current map
        ArrayDeleteItem(g_NextMapNamesArray, currentMapIndex);
    }
}

@fillNextMapsArrayWithPreviousMaps()
{
    // first we load last maps played
    if(file_exists(LAST_MAPS_PLAYED_FILE_PATH))
    {   
        new lineText[64], len;
        
        for(new i = 0; read_file(LAST_MAPS_PLAYED_FILE_PATH, i, lineText, 63, len); ++i) 
        {
            trim(lineText)
            
            /* If this is empty line */
            if(!strlen(lineText))
                continue;
            
            /* Remove "" */
            remove_quotes(lineText);
            
            log_amx("Loaded last map: %s.", lineText);

            ArrayPushString(g_NextMapNamesArray, lineText);

            // If we already loaded as much last maps playe as we can
            if (ArraySize(g_NextMapNamesArray) >= NUMBER_OF_MAPS_TO_STORE_AS_LAST_PLAYED) 
            {
                break;
            }
        }
    }
}

@initPlayersInVoteZoneArrays()
{
    // first we create array to store player ids in
    g_PlayersInMapVoteZoneArray = ArrayCreate();

    // now we create new arrays by next map array
    // next map array is filled at this time so we know how much vote zones should be created
    new mapsCount = ArraySize(g_NextMapNamesArray);
    for(new i = 0; i < mapsCount; ++i)
    {
        ArrayPushCell(g_PlayersInMapVoteZoneArray, ArrayCreate());
    }
}

@createMapVoteZones()
{
    new mapsCount = ArraySize(g_NextMapNamesArray);
    for(new i = 0; i < mapsCount; ++i)
    {
        new ent = g_MapVoteZoneEntity[i] = @createMapVoteEntity(i);
        
        new headerEnt = @createMapVoteHeaderEntity(i);
         
        entity_set_int(ent, EV_INT_mapvote_header, headerEnt);
	}
}

@removeAllMapVoteEntities()
{
    if (g_NextMapNamesArray == Invalid_Array) 
    {
        return;
    }

    new mapsCount = ArraySize(g_NextMapNamesArray);
    for(new i = 0; i < mapsCount; ++i)
    {
        if (is_valid_ent(g_MapVoteZoneEntity[i]))
        {
            new spriteEnt = entity_get_int(g_MapVoteZoneEntity[i], EV_INT_mapvote_header);

            if (is_valid_ent(spriteEnt)) 
            {
                remove_entity(spriteEnt);
            }

            remove_entity(g_MapVoteZoneEntity[i]);
        }
    }
}

@createMapVoteEntity(index)
{
    new ent = create_entity("trigger_multiple");
    
    entity_set_string(ent, EV_SZ_classname, MAPVOTE_CLASSNAME);
    set_pev(ent, pev_origin, g_MapVoteZoneCoordinations[index][0]);
    
    dllfunc(DLLFunc_Spawn, ent);

    entity_set_size(ent, g_MapVoteZoneCoordinations[index][1], g_MapVoteZoneCoordinations[index][2]);
    
    entity_set_int(ent, EV_INT_mapvote_index, index + 1);
    
    set_pev(ent, pev_solid, SOLID_TRIGGER);
    set_pev(ent, pev_movetype, MOVETYPE_NONE);
    
    set_pev(ent, pev_nextthink, get_gametime() + 1.0);

    return ent;
}

@createMapVoteHeaderEntity(index)
{
    new ent = create_entity("env_sprite");
    
    new Float:headerOrigin[3];
    headerOrigin[0] = g_MapVoteZoneCoordinations[index][0][0];
    headerOrigin[1] = g_MapVoteZoneCoordinations[index][0][1];
    headerOrigin[2] = g_MapVoteZoneCoordinations[index][0][2] + 55.0;
    
    entity_set_vector(ent, EV_VEC_origin, headerOrigin);
    entity_set_model(ent, g_MapVoteSpritePath);
    entity_set_float(ent, EV_FL_scale, 0.7);

    new mapName[64];
    ArrayGetString(g_NextMapNamesArray, index, mapName, 63);

    if(containi(mapName, RESTART_MAP_NAME) == -1)
        entity_set_float(ent, EV_FL_frame, (1.0 * (index + 1)));
    else
        entity_set_float(ent, EV_FL_frame, 0.0);
    
    fm_set_rendering(ent, kRenderFxNone, 0, 0, 0, kRenderTransAdd, 255);

    set_pev(ent, pev_origin, headerOrigin);

    return ent;
}

@drawVoteMapLine(Float:x1, Float:y1, Float:z1, Float:x2, Float:y2, Float:z2) 
{
	new Float:start[3], Float:stop[3];
	start[0] = x1;
	start[1] = y1;
	start[2] = z1 - 20.0;
	
	stop[0] = x2;
	stop[1] = y2;
	stop[2] = z2 - 20.0;
	
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_BEAMPOINTS)
	engfunc(EngFunc_WriteCoord, start[0])
	engfunc(EngFunc_WriteCoord, start[1])
	engfunc(EngFunc_WriteCoord, start[2])
	engfunc(EngFunc_WriteCoord, stop[0])
	engfunc(EngFunc_WriteCoord, stop[1])
	engfunc(EngFunc_WriteCoord, stop[2])
	write_short(g_SpriteWhiteLine)
	write_byte(1)
	write_byte(5)
	write_byte(10) // duration
	write_byte(20)
	write_byte(0)
	write_byte(0)	// RED
	write_byte(50)	// GREEN
	write_byte(355)	// BLUE					
	write_byte(250)	// brightness
	write_byte(5)
	message_end()
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