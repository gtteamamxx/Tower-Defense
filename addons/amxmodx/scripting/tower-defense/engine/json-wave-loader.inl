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
        @showFailMessage("[Wave] Plik konfiguracyjny %s nie posiada wavów", jsonFilePath);
    }
    else
    {
        @loadWaves(wavesJsonObject, 
            .count = wavesCount, 
            .filePath = jsonFilePath,
            .hasDefaultConfig = wavesHaveDefaultConfig);
    }
    
    json_free(wavesJsonObject);
    json_free(json);
}

@loadWaves(JSON:json, count, filePath[128], bool:hasDefaultConfig)
{
    new waveNumberString[3];

    /* Waves are begining from 1 to X*/
    for(new i = 1; i <= count; ++i)
    {
        num_to_str(i, waveNumberString, charsmax(waveNumberString));

        new JSON:waveJsonObject = json_object_get_value(json, waveNumberString);

        if(waveJsonObject == Invalid_JSON)
        {
            @showFailMessage("[Wave] Nieprawidłowy numer wave: %d w pliku konfiguracyjnym %s.", i, filePath);
        }
        else if(!json_is_array(waveJsonObject))
        {
            @showFailMessage("[Wave] Nieprawidłowy wave: %d w pliku konfiguracyjnym %s.", i, filePath);
        }
        else 
        {
            @loadWaveConfiguration(waveJsonObject, 
                .waveNumber = i, 
                .filePath = filePath,
                .hasDefaultConfig = hasDefaultConfig);
        }

        json_free(waveJsonObject);
    }
}

@loadWaveConfiguration(JSON:waveJsonObject, waveNumber, filePath[128], bool:hasDefaultConfig)
{
    new monsterTypesCount = json_array_get_count(waveJsonObject);
    if(monsterTypesCount == 0)
    {
        @showFailMessage("[Wave] Wave %d nie posiada żadnego typu potworów w pliku konfiguracyjnym %s", waveNumber, filePath);
        return;
    }

    @initWaveTrie();
    
    for(new i = 0; i < monsterTypesCount; ++i)
    {
        new JSON:monsterTypeJson = json_array_get_value(waveJsonObject, i);
        if(!@isJsonValid(monsterTypeJson))
        {
            @showFailMessage("[Wave] Konfiguracja dla Wave %d, typu nr %d jest nieprawidłowa w pliku konfiguracyjnym %s", waveNumber, i, filePath);
        }
        else 
        {
            @loadMonsterTypeDataForWave(monsterTypeJson, waveNumber,
                .monsterTypeIndex = i,
                .filePath = filePath);
        }

        json_free(monsterTypeJson);
    }
}

@loadMonsterTypeDataForWave(JSON:monsterTypeJson, waveNumber, monsterTypeIndex, filePath[128])
{
    new numberOfPropertiesForMonsterTypeData = json_object_get_count(monsterTypeJson);

    if(numberOfPropertiesForMonsterTypeData == 0)
    {
        @showFailMessage("[Wave] Konfiguracja dla Wave %d, typu nr %d jest nieprawidłowa w pliku konfiguracyjnym %s.", waveNumber, monsterTypeIndex, filePath);
        return;
    }

    new Array:waveArray = Array:ArrayGetCell(g_WaveDataArray, waveNumber-1);
    new Trie:monsterTypeTrie = TrieCreate();
    ArrayPushCell(waveArray, monsterTypeTrie);

    new key[WAVE_MONSTER_TYPE_KEY_LENGTH], dataType;
    for(new i = 0; i < numberOfPropertiesForMonsterTypeData; ++i)
    {
        json_object_get_name(monsterTypeJson, i, key, charsmax(key));

        if(!@checkIfMonsterTypeJsonIsValid(key, WAVE_MONSTER_DATA_ENUM:dataType, waveNumber, filePath))
        {
            return;
        }

        new stringDataTypeIndex[4];
        num_to_str(dataType, stringDataTypeIndex, charsmax(stringDataTypeIndex));

        if(WAVE_MONSTER_DATA_ENUM:dataType == TYPE) 
        {
            new monsterType[33], JSON:typeJson = json_object_get_value(monsterTypeJson, key);
            if(!json_is_string(typeJson))
            {
                @showFailMessage(
                    "[Wave] Wave: %d, typ nr %d, klucz: %s ma nieprawidłową wartość w pliku konfiguracyjnym %s", 
                    waveNumber, monsterTypeIndex, key, filePath);
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
                @showFailMessage(
                    "[Wave] Wave: %d, typ nr %d, klucz: %s. Wartość nie jest ujęta w tablicy. [] w pliku konfiguracyjnym %s.", 
                    waveNumber, monsterTypeIndex, key, filePath);
                return;
            }

            new any:minValue, any:maxValue;
            new bool:isFloatValue = WAVE_MONSTER_DATA_ENUM:dataType != COUNT;

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
        log_amx("[Wave] Tablica dla klucza %s ma błędne wartości.", key);
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
        log_amx("[Wave] Plik konfiguracyjny %s nie jest prawidłowym plikiem JSON", filePath);
    }
    else if(!@jsonHasWavesSchema(json))
    {
        log_amx("[Wave] Plik konfiguracyjny %s nie posiada klucza %s", filePath, WAVES_SCHEMA);
    }
    else
    {
        return true;
    }

    return false;
}

bool:@checkIfMonsterTypeJsonIsValid(key[], &WAVE_MONSTER_DATA_ENUM:dataType, waveNumber, filePath[128])
{
    if(!TrieKeyExists(g_WavesConfigurationKeysTrie, key))
    {
        @showFailMessage("[Wave] Wave: %d, nie rozpoznano klucza %s w pliku konfiguracyjnym %s.", waveNumber, key, filePath);
        return false;
    }
    else if(!TrieGetCell(g_WavesConfigurationKeysTrie, key, dataType))
    {
        @showFailMessage("[Wave] Wave: %d, błąd odczytu wartości dla klucza %s w pliku konfiguracyjnym %s", waveNumber, key, filePath);
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

@initWaveTrie()
{
    new Array:waveArray = ArrayCreate();
    ArrayPushCell(g_WaveDataArray, waveArray);
}