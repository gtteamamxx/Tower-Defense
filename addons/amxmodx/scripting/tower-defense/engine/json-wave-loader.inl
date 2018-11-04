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
    new bool:wavesHaveDefaultConfig = @checkIfWavesHaveDefaultConfig(wavesJsonObject);

    new wavesCount = json_object_get_count(wavesJsonObject);
    if(wavesHaveDefaultConfig)
    {
        wavesCount -= 1;
    }

    if(wavesCount == 0) 
    {
        log_amx("[Wave] Plik konfiguracyjny %s nie posiada wavów", jsonFilePath);
    }
    else
    {
        if(wavesHaveDefaultConfig)
        {
            //@loadDefaultValuesForWave(wavesJsonObject);
        }

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
            log_amx("[Wave] Nieprawidłowy numer wave: %d w pliku konfiguracyjnym %s.", i, filePath);
            setGameStatus(.status = false);
        }
        else if(!json_is_array(waveJsonObject))
        {
            log_amx("[Wave] Nieprawidłowy wave: %d w pliku konfiguracyjnym %s.", i, filePath);
            setGameStatus(.status = false);
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
    new monsterTypesCount = json_object_get_count(wavesJsonObject);
    if(monsterTypesCount == 0)
    {
        log_amx("[Wave] Wave %d nie posiada żadnego typu potworów w pliku konfiguracyjnym %s", waveNumber, filePath);
        setGameStatus(.status = false);
        return;
    }

    for(new i = 0; i < monsterTypesCount; ++i)
    {
        
    }
}

bool:@checkIfWavesHaveDefaultConfig(JSON:json)
{
    return json_object_has_value(json, WAVES_DEFAULT_SCHEMA);
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

bool:@isJsonValid(JSON:json)
{
    return json_is_object(json);
}

bool:@jsonHasWavesSchema(JSON:json)
{
    return json_object_has_value(json, WAVES_SCHEMA);
}

