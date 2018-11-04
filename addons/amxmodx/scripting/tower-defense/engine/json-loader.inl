#if defined td_engine_jsonloader_includes
  #endinput
#endif
#define td_engine_jsonloader_includes

public loadMapConfigFromJsonFile(jsonFilePath[128])
{
    new JSON:json = json_parse(jsonFilePath, .is_file = true, .with_comments = true);

    if(!json_is_object(json))
    {
        log_amx("Plik konfiguracyjny nie jest prawidłowym plikiem JSON");
        json_free(json);
        return;
    }

    new itemsCount = json_object_get_count(json);

    for(new i = 0; i < itemsCount; ++i)
    {
        @loadMapConfigurationFromJsonLine(json, .line = i);
    }

    json_free(json);
}

@loadMapConfigurationFromJsonLine(JSON:json, line)
{
    new key[MAP_CONFIG_KEY_LENGTH], type;
    json_object_get_name(json, line, key, charsmax(key));

    if(!TrieKeyExists(g_MapConfigurationKeysTrie, key)
    || !TrieGetCell(g_MapConfigurationKeysTrie, key, type))
    {
        log_amx("Nie można wczytać konfiguracji dla klucza: %s", key);
        return -1;
    }

    @setMapConfigurationValueByType(json, MAP_CONFIGURATION_ENUM:type, key);

    return type;
}

@setMapConfigurationValueByType(JSON:json, MAP_CONFIGURATION_ENUM:type, key[])
{
    new JSON:jsonConfigValue = json_object_get_value(json, key);
    if(jsonConfigValue == Invalid_JSON)
    {
        log_amx("Nie można wczytać konfiguracji dla klucza: %s", key);
        return;
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
            log_amx("Nie można wczytać konfiguracji dla klucza: %s", key);
        }
    }

    json_free(jsonConfigValue)
}