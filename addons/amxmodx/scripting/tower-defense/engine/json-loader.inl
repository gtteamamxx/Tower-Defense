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

    new count = json_object_get_count(json);

    for(new i = 0; i < count; ++i)
    {
        @loadConfigurationFromJsonLine(json, .line = i);
    }

    json_free(json);
}

@loadConfigurationFromJsonLine(JSON:json, line)
{
    new key[MAP_CONFIG_KEY_LENGTH];
    json_object_get_name(json, line, key, charsmax(key));

    for(new i = 0; i < _:MAP_CONFIGURATION_ENUM; i++)
    {
        static MAP_CONFIGURATION_ENUM:type; type = MAP_CONFIGURATION_ENUM:i;

        if(strcmp(g_MapConfigurationKeys[type], key))
        {
            @setMapConfigurationValueByType(json, type, key);
            break;
        }
    }
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
            setMapConfigDataCell(type, json_object_get_number(json, key));
        }
        case JSONBoolean:
        {
            setMapConfigDataCell(type, json_object_get_bool(json, key));
        }
        case JSONString:
        {
            new value[64];
            json_object_get_string(json, key, value, charsmax(value));
            setMapConfigDataString(type, value);
        }
        default:
        {
            log_amx("Nie można wczytać konfiguracji dla klucza: %s", key);
        }
    }

    json_free(jsonConfigValue)
}