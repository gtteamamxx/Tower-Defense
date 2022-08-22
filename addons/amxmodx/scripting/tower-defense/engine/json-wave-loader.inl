#if defined td_json_wave_loader_included
  #endinput
#endif
#define td_json_wave_loader_included

public loadWavesFromFile(jsonFilePath[128])
{
    new JSON:json = json_parse(jsonFilePath, .is_file = true, .with_comments = true);
    if(!@checkWaveJsonFileIsValid(json, .filePath = jsonFilePath))
    {
        setGameStatus(.status = false);
        json_free(json);
        return;
    }

    new JSON:wavesJsonObject = json_object_get_value(json, WAVES_SCHEMA);

    new wavesCount = json_object_get_count(wavesJsonObject);

    if(wavesCount == 0) 
    {
        @showFailMessage("[Wave] Configuration file '%s' doesn't have waves. (waves count equals to 0)", jsonFilePath);
    }
    else
    {
        log_amx("[Wave] Loading configuration file: %s", jsonFilePath);
        @loadWaves(wavesJsonObject, 
            .count = wavesCount, 
            .filePath = jsonFilePath);
    }
    
    json_free(wavesJsonObject);
    json_free(json);
}

@loadWaves(JSON:json, count, filePath[128])
{
    new waveNumberString[3];

    /* Waves are begining from 1 to X*/
    for(new i = 1; i <= count; ++i)
    {
        num_to_str(i, waveNumberString, charsmax(waveNumberString));

        new JSON:waveJsonObject = json_object_get_value(json, waveNumberString);

        if(waveJsonObject == Invalid_JSON)
        {
            @showFailMessage("[Wave] Bad wave number: %d in configuration file. (invalid json)", i);
        }
        else if(!json_is_object(waveJsonObject))
        {
            @showFailMessage("[Wave] Bad wave configuration. Wave number: %d. (json is not an object)", i);
        }
        else 
        {
            new Array:waveArray = @initWaveTrie();
            @initConfigurationTrieForWaveArray(waveArray);
            @initWaveMonsterTypesArrayForWaveArray(waveArray);
            @initWaveMonsterCountArrayForWaveArray(waveArray);

            @setInitialConfigurationForWaveArray(waveArray);

            @loadWaveConfiguration(waveJsonObject, .waveNumber = i, .waveArray = waveArray);
            @loadWaveMonsterTypes(waveJsonObject, .waveNumber = i);
        }

        json_free(waveJsonObject);
    }
}

@setInitialConfigurationForWaveArray(Array:waveArray)
{
    new Trie:waveConfigurationTrie = Trie:ArrayGetCell(waveArray, _:WAVE_CONFIG);
    @setWaveTimeToWaveConfiguration(waveConfigurationTrie);
}

@setWaveTimeToWaveConfiguration(Trie:waveConfigurationTrie)
{
    new timeToWave = getMapConfigurationData(MAP_TIME_TO_WAVE);

    new key[WAVE_CONFIGURATION_KEY_LENGTH];
    num_to_str(_:WAVE_TIME_TO_WAVE, key, charsmax(key));

    TrieSetCell(waveConfigurationTrie, key, timeToWave);
}

@initConfigurationTrieForWaveArray(Array:waveArray)
{
    new Trie:waveConfigurationTrie = TrieCreate();
    ArrayPushCell(waveArray, waveConfigurationTrie);
}

@initWaveMonsterTypesArrayForWaveArray(Array:waveArray)
{
    new Array:monsterTypesArrayForWave = ArrayCreate();
    ArrayPushCell(waveArray, monsterTypesArrayForWave);
}

@initWaveMonsterCountArrayForWaveArray(Array:waveArray)
{
    new Array:monsterCountArrayForWave = ArrayCreate();
    ArrayPushCell(waveArray, monsterCountArrayForWave);
}


@initMonsterTypeTrieForWaveMonsterTypeArray(Array:waveMonsterTypeArray)
{
    new Trie:monsterTypeTrie = TrieCreate();
    ArrayPushCell(waveMonsterTypeArray, monsterTypeTrie);
}

@loadWaveConfiguration(JSON:waveJsonObject, waveNumber, Array:waveArray)
{
    if(!json_object_has_value(waveJsonObject, WAVE_CONFIG_SCHEMA))
    {
        return;
    }

    new JSON:waveConfigurationJson = json_object_get_value(waveJsonObject, WAVE_CONFIG_SCHEMA);

    if(!@isJsonValid(waveConfigurationJson))
    {
        log_amx("[Wave] Bad configuration for wave %d. (json is not an object)", waveNumber);
        json_free(waveConfigurationJson);
        return;
    }

    new key[WAVE_CONFIGURATION_KEY_LENGTH], type, typeNumberString[4];
    new configurationItemsCount = json_object_get_count(waveConfigurationJson);

    new Trie:waveConfigurationTrie = Trie:ArrayGetCell(waveArray, _:WAVE_CONFIG);

    for(new i = 0; i < configurationItemsCount; ++i)
    {
        json_object_get_name(waveConfigurationJson, i, key, charsmax(key));

        if(!TrieKeyExists(g_WavesConfigurationKeysTrie, key)
        || !TrieGetCell(g_WavesConfigurationKeysTrie, key, type))
        {
            @showFailMessage("[Wave] Undefined key %s in wave %d. (key doesn't exist)", key, waveNumber);
            continue;
        }

        new JSON:configurationValueJson = json_object_get_value(waveConfigurationJson, key);
        if(!json_is_number(configurationValueJson))
        {
            @showFailMessage("[Wave] Key %s of wave %d. Allowed only integer values. (json is not a number)", key, waveNumber);
        }
        else
        {
            num_to_str(type, typeNumberString, charsmax(typeNumberString));
            new value = json_get_number(configurationValueJson);
            TrieSetCell(waveConfigurationTrie, typeNumberString, value, .replace = true);
        }

        json_free(configurationValueJson);
    }

    json_free(waveConfigurationJson);
}

@loadWaveMonsterTypes(JSON:waveJsonObject, waveNumber)
{
    if(!json_object_has_value(waveJsonObject, WAVE_MONSTER_TYPES_SCHEMA))
    {
        @showFailMessage("[Wave] Wave %d doesn't have key %s which specifies monster types. (json object not found)", waveNumber, WAVE_MONSTER_TYPES_SCHEMA);
        return;
    }

    new JSON:monsterTypesJson = json_object_get_value(waveJsonObject, WAVE_MONSTER_TYPES_SCHEMA);
    if(!json_is_array(monsterTypesJson))
    {
        @showFailMessage("[Wave] Wave %d has bad configuration of monster types. (json is not array)", waveNumber);
        json_free(monsterTypesJson);
        return;
    }

    new monsterTypesCount = json_array_get_count(monsterTypesJson);
    if(monsterTypesCount == 0)
    {
        @showFailMessage("[Wave] Wave %d don't have any monster types. (monster types count is equal 0)", waveNumber);
        json_free(monsterTypesJson);
        return;
    }
    
    for(new i = 0; i < monsterTypesCount; ++i)
    {
        new JSON:monsterTypeJson = json_array_get_value(monsterTypesJson, i);
        if(!@isJsonValid(monsterTypeJson))
        {
            @showFailMessage("[Wave] Configuration of wave %d, monster index %d is not valid. (json is not an object)", waveNumber, i);
        }
        else 
        {
            new Array:waveArray = ArrayGetCell(g_WaveDataArray, waveNumber - 1);
            new Array:waveMonsterTypesArray = ArrayGetCell(waveArray, _:WAVE_MONSTER_TYPES);

            @initMonsterTypeTrieForWaveMonsterTypeArray(waveMonsterTypesArray);

            @loadMonsterTypeDataForWave(monsterTypeJson, waveNumber,
                .monsterTypeIndex = i,
                .waveArray = waveArray);
        }

        json_free(monsterTypeJson);
    }

    json_free(monsterTypesJson);
}

@loadMonsterTypeDataForWave(JSON:monsterTypeJson, waveNumber, monsterTypeIndex, Array:waveArray)
{
    new numberOfPropertiesForMonsterTypeData = json_object_get_count(monsterTypeJson);

    if(numberOfPropertiesForMonsterTypeData == 0)
    {
        @showFailMessage("[Wave] Configuration for wave %d, monster index %d is not valid. (monster type doesn't have any properties)", waveNumber, monsterTypeIndex);
        return;
    }

    new key[WAVE_MONSTER_TYPE_KEY_LENGTH], dataType;
    new Array:monsterTypesArray = Array:ArrayGetCell(waveArray, _:WAVE_MONSTER_TYPES);
    new Trie:monsterTypeTrie = Trie:ArrayGetCell(monsterTypesArray, monsterTypeIndex);

    for(new i = 0; i < numberOfPropertiesForMonsterTypeData; ++i)
    {
        json_object_get_name(monsterTypeJson, i, key, charsmax(key));

        if(!@checkIfMonsterTypeJsonIsValid(key, WAVE_MONSTER_DATA_ENUM:dataType, waveNumber))
        {
            return;
        }

        new stringDataTypeIndex[4];
        num_to_str(dataType, stringDataTypeIndex, charsmax(stringDataTypeIndex));

        if(WAVE_MONSTER_DATA_ENUM:dataType == MONSTER_TYPE) 
        {
            new monsterType[33], JSON:typeJson = json_object_get_value(monsterTypeJson, key);
            if(!json_is_string(typeJson))
            {
                @showFailMessage("[Wave] Wave %d, monster index %d, key %s has bad value. (value is not a string)", waveNumber, monsterTypeIndex, key);
            }
            else
            {
                json_object_get_string(monsterTypeJson, key, monsterType, charsmax(monsterType));
                TrieSetString(monsterTypeTrie, stringDataTypeIndex, monsterType);
            }

            json_free(typeJson);
        }
        else
        {
            new JSON:minMaxArrayJson = json_object_get_value(monsterTypeJson, key);
            if(!json_is_array(minMaxArrayJson))
            {
                @showFailMessage("[Wave] Wave: %d, monster index %d, key %s has bad value. (value is not an array [])", waveNumber, monsterTypeIndex, key);
                json_free(minMaxArrayJson);
                return;
            }

            new any:minValue, any:maxValue;
            new bool:isFloatValue = 
                   WAVE_MONSTER_DATA_ENUM:dataType != MONSTER_COUNT
                && WAVE_MONSTER_DATA_ENUM:dataType != MONSTER_TOWER_DAMAGE;

            if(!getMinMaxValueFromArray(minMaxArrayJson, minValue, maxValue, key, .float = isFloatValue))
            {
                setGameStatus(.status = false);
                return;
            }
            else
            {
                new any:value[2];
                value[0] = minValue
                value[1] = maxValue;

                TrieSetArray(monsterTypeTrie, stringDataTypeIndex, value, sizeof value);
            }

            json_free(minMaxArrayJson);
        }
    }
}

stock bool:getMinMaxValueFromArray(JSON:arrayJson, &any:minValue, &any:maxValue, key[], bool:float = true)
{
    new valuesCount = json_array_get_count(arrayJson);
    if(valuesCount == 0 || valuesCount > 2)
    {
        log_amx("[Wave] Array for key %s has bad values. (number of elements in an array isn't equal to 1 or 2)", key);
        return false;
    }

    if(float)
    {
        minValue = json_array_get_real(arrayJson, 0);
    }
    else
    {
        minValue = json_array_get_number(arrayJson, 0);
    }

    if(valuesCount == 2)
    {
        if(float)
        {
            maxValue = json_array_get_real(arrayJson, 1);
        }
        else 
        {
            maxValue = json_array_get_number(arrayJson, 1);
        }
    }

    return true;
}

bool:@checkWaveJsonFileIsValid(JSON:json, filePath[128])
{
    if(!@isJsonValid(json))
    {
        log_amx("[Wave] Configuration file %s isn't valid JSON file. (json is not an object)", filePath);
    }
    else if(!@jsonHasWavesSchema(json))
    {
        log_amx("[Wave] Key %s not found in configuratoin file %s.", WAVES_SCHEMA, filePath);
    }
    else
    {
        return true;
    }

    return false;
}

bool:@checkIfMonsterTypeJsonIsValid(key[], &WAVE_MONSTER_DATA_ENUM:dataType, waveNumber)
{
    if(!TrieKeyExists(g_MonsterTypesConfigurationKeysTrie, key))
    {
        @showFailMessage("[Wave] Wave %d, undefined key %s.", waveNumber, key);
        return false;
    }
    else if(!TrieGetCell(g_MonsterTypesConfigurationKeysTrie, key, dataType))
    {
        @showFailMessage("[Wave] Wave %d, error durning loading value from memory of key. (trie get cell error)", waveNumber, key);
        return false;
    }

    return true;
}

bool:@isJsonValid(JSON:json)
{
    return json_is_object(json);
}

bool:@jsonHasWavesSchema(JSON:json)
{
    return json_object_has_value(json, WAVES_SCHEMA);
}

@showFailMessage(const error[], any:...)
{
    new errorMessage[256];
    vformat(errorMessage, charsmax(errorMessage), error, 2);
    log_amx(errorMessage);
    setGameStatus(.status = false);
}

Array:@initWaveTrie()
{
    new Array:waveArray = ArrayCreate();
    ArrayPushCell(g_WaveDataArray, waveArray);

    return waveArray;
}