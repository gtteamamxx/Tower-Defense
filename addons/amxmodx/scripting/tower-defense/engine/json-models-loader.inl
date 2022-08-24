#if defined td_engine_json_models_loader_includes
  #endinput
#endif
#define td_engine_json_models_loader_includes

public loadModelsConfigurationFromFile(jsonFilePath[128])
{
    new JSON:json = json_parse(jsonFilePath, .is_file = true, .with_comments = true);

    if(!json_is_object(json))
    {
        log_amx("[Models] Configuration file is not valid JSON file");
        setGameStatus(.status = false);
        json_free(json);
        return;
    }

    new itemsCount = json_object_get_count(json);

    for(new i = 0; i < itemsCount; ++i)
    {
        @loadModelsConfigurationFromLine(json, .line = i);
    }

    logBadValues(g_ModelsConfigurationKeysTrie);
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
}

@loadMainModelsConfiguration(JSON:json)
{
    new key[MODELS_CONFIG_KEY_LENGTH], type;
    new itemsCount = json_object_get_count(json);
    for(new i = 0; i < itemsCount; ++i)
    {
        json_object_get_name(json, i, key, charsmax(key));

        if(!isTrieValid(g_ModelsConfigurationKeysTrie, key, type))
        {
            log_amx("[Models] Undefined key: %s. ", key);
            setGameStatus(.status = false);
            continue;
        }

        new path[MODELS_CONFIG_PATH_LENGTH];
        json_object_get_string(json, key, path, charsmax(path));

        copy(g_Models[MODELS_ENUM:type], charsmax(path), path);

        TrieDeleteKey(g_ModelsConfigurationKeysTrie, key);
    }
}
