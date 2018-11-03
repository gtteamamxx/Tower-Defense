#if defined td_engine_jsonloader_includes
  #endinput
#endif
#define td_engine_jsonloader_includes

public loadMapConfigFromJsonFile(jsonFilePath[128])
{
    new JSON:json = json_parse(jsonFilePath, .is_file = true, .with_comments = true);

    if(!json_is_array(json))
    {
        log_amx("Plik konfiguracyjny nie jest prawidłowym plikiem JSON");
        json_free(json);
        return;
    }

    new count = json_array_get_count(json);

    for(new i = 0; i < count; ++i)
    {
    }

    json_free(json);
}