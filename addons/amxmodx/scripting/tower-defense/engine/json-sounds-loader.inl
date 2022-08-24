#if defined td_engine_json_sounds_loader_includes
  #endinput
#endif
#define td_engine_json_sounds_loader_includes

public loadSoundsConfigurationFromFile(jsonFilePath[128])
{
    // load sounds config file
    new JSON:json = json_parse(jsonFilePath, .is_file = true, .with_comments = true);

    // if config file is bad then fail
    if(!json_is_object(json))
    {
        log_amx("[Sounds] Configuration file is not valid JSON file");
        setGameStatus(.status = false);
        json_free(json);
        return;
    }

    // get number of sound keys
    new itemsCount = json_object_get_count(json);

    // loop through all sound keys
    for(new i = 0; i < itemsCount; ++i)
    {
        // load sounds from specified key
        @loadSoundsFromLine(json, .line = i);
    }

    // log bad values if there's any
    logBadValues(g_SoundsConfigurationKeysTrie);

    // clear memory
    json_free(json);
}

@loadSoundsFromLine(JSON:json, line)
{
    // get json property key
    new key[128];
    json_object_get_name(json, line, key, charsmax(key));

    // if key is valid configuration file
    if(TrieKeyExists(g_SoundsConfigurationKeysTrie, key))
    {
        // get it's array
        new JSON:soundsArrayJson = JSON:json_object_get_value(json, key);

        // if it's not an array skip
        if (!json_is_array(soundsArrayJson))
        {
            log_amx("[Sounds] Key %s is not an array.", key);
            return;
        }

        // load all sounds for specified key from an array
        @loadSoundsFromArray(soundsArrayJson, key);        

        // free array json handle
        json_free(soundsArrayJson);
    }
}

 @loadSoundsFromArray(JSON:soundsArrayJson, key[128])
 {
    // get number of sounds
    new numberOfSounds = json_array_get_count(soundsArrayJson);

    // get sound index
    new SOUND_ENUM:soundIndex;
    TrieGetCell(g_SoundsConfigurationKeysTrie, key, soundIndex);

    // get sound array
    new Array:soundPathsArray = Array:ArrayGetCell(g_SoundsConfigurationPathsArray, _:soundIndex);

    // loop through all sound paths in array
    for(new i = 0; i < numberOfSounds; ++i) 
    {
        // get json object of array item at specified index
        new JSON:soundObject = JSON:json_array_get_value(soundsArrayJson, i);
        
        // if array item is string
        if (json_is_string(soundObject)) 
        {
            // get sound path
            new soundPath[128];
            json_array_get_string(soundsArrayJson, i, soundPath, 127);

            // push sound path to sounds array
            ArrayPushString(soundPathsArray, soundPath);
        }
        // if array item is not string it's fail
        else
        {
            log_amx("[Sounds] Key %s has array and index %d is not string", key, i);
        }

        json_free(soundObject);
    }

    // remove from sounds key trie to mark is as read
    TrieDeleteKey(g_SoundsConfigurationKeysTrie, key);
 }