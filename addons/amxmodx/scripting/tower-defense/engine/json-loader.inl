#if defined td_engine_jsonloader_includes
  #endinput
#endif
#define td_engine_jsonloader_includes

public loadModelsConfigurationFromFile(jsonFilePath[128])
{
    new JSON:json = json_parse(jsonFilePath, .is_file = true, .with_comments = true);

    if(!json_is_object(json))
    {
        log_amx("[Models] Plik konfiguracyjny nie jest prawidłowym plikiem JSON");
        setGameStatus(.status = false);
        json_free(json);
        return;
    }

    new itemsCount = json_object_get_count(json);

    for(new i = 0; i < itemsCount; ++i)
    {
        @loadModelsConfigurationFromLine(json, .line = i);
    }

    @logBadValues(g_ModelsConfigurationKeysTrie);
    json_free(json);
}

@loadModelsConfigurationFromLine(JSON:json, line)
{
    new key[MODELS_CONFIG_KEY_LENGTH];
    json_object_get_name(json, line, key, charsmax(key));

    if(equal(key, MODEL_MAIN_SCHEMA))
    {
        new JSON:mainJsonObject = json_object_get_value(json, key);
        @loadMainModelsConfiguration(mainJsonObject);
        json_free(mainJsonObject);
    }
    else
    {
        log_amx("[Models] Nie znaleziono konfiguracji dla klucza: %s", key);
        setGameStatus(.status = false);
    }
}

@loadMainModelsConfiguration(JSON:json)
{
    new key[MODELS_CONFIG_KEY_LENGTH], type;
    new itemsCount = json_object_get_count(json);
    for(new i = 0; i < itemsCount; ++i)
    {
        json_object_get_name(json, i, key, charsmax(key));

        if(!@isTrieValid(g_ModelsConfigurationKeysTrie, key, type))
        {
            log_amx("[Models] Nie rozpoznano klucza: %s. ", key);
            setGameStatus(.status = false);
            continue;
        }

        new path[MODELS_CONFIG_PATH_LENGTH];
        json_object_get_string(json, key, path, charsmax(path));

        copy(g_Models[MODELS_ENUM:type], charsmax(path), path);

        TrieDeleteKey(g_ModelsConfigurationKeysTrie, key);
    }
}

public loadMapConfigFromJsonFile(jsonFilePath[128])
{
    new JSON:json = json_parse(jsonFilePath, .is_file = true, .with_comments = true);

    if(!json_is_object(json))
    {
        log_amx("[Map] Plik konfiguracyjny nie jest prawidłowym plikiem JSON");
        setGameStatus(.status = false);
        json_free(json);
        return;
    }

    new itemsCount = json_object_get_count(json);

    for(new i = 0; i < itemsCount; ++i)
    {
        @loadMapConfigurationFromJsonLine(json, .line = i);
    }

    @logBadValues(g_MapConfigurationKeysTrie);

    json_free(json);
}

@loadMapConfigurationFromJsonLine(JSON:json, line)
{
    new key[MAP_CONFIG_KEY_LENGTH], type;
    json_object_get_name(json, line, key, charsmax(key));

    if(!@isTrieValid(g_MapConfigurationKeysTrie, key, type))
    {
        log_amx("[Map] Nie rozpoznano klucza: %s", key);
        return;
    }

    new bool:isValueValid = @setMapConfigurationValueByType(json, MAP_CONFIGURATION_ENUM:type, key);
    if(isValueValid)
    {
        TrieDeleteKey(g_MapConfigurationKeysTrie, key);
    }
    else
    {
        setGameStatus(.status = false);
    }
}

bool:@setMapConfigurationValueByType(JSON:json, MAP_CONFIGURATION_ENUM:type, key[])
{
    new JSON:jsonConfigValue = json_object_get_value(json, key);
    if(jsonConfigValue == Invalid_JSON)
    {
        log_amx("[Map] Nie można wczytać konfiguracji dla klucza: %s", key);
        return false;
    }

    switch(json_get_type(jsonConfigValue))
    {
        case JSONNumber: 
        {
            setMapConfigurationData(type, json_object_get_number(json, key));
        }
        case JSONBoolean:
        {
            setMapConfigurationData(type, json_object_get_bool(json, key));
        }
        default:
        {
            log_amx("[Map] Nie można wczytać konfiguracji dla klucza: %s", key);
            setGameStatus(.status = false);
        }
    }

    json_free(jsonConfigValue)

    return true;
}

@isTrieValid(Trie:trie, key[], &type)
{
    return TrieKeyExists(trie, key) && TrieGetCell(trie, key, type);
}

@logBadValues(Trie:trie)
{
    new TrieIter:trieIteration = TrieIterCreate(trie);

    new key[128];
    while(!TrieIterEnded(trieIteration))
    {
        TrieIterGetKey(trieIteration, key, charsmax(key));

        log_amx("Nieprawidłowa wartośc dla konfiguracji: %s", key);
        setGameStatus(.status = false);

        TrieIterNext(trieIteration);
    }

    TrieIterDestroy(trieIteration);
}