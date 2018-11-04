#if defined td_engine_precaches_includes
  #endinput
#endif
#define td_engine_precaches_includes

public plugin_precache()
{
    @initTries();

    loadModelsConfiguration();

    for(new i = 0; i < _:MODELS_ENUM; ++i)
    {
        precache_model(g_Models[MODELS_ENUM:i]);
    }
}

@initTries()
{
    @initMapConfigurationTrie();
    @initModelsConfigurationTrie();
    @initWavesConfigurationTrie();
}

@initModelsConfigurationTrie()
{
    g_ModelsConfigurationKeysTrie = TrieCreate();

    TrieSetCell(g_ModelsConfigurationKeysTrie, "TOWER_MODEL", _:TOWER_MODEL);
    TrieSetCell(g_ModelsConfigurationKeysTrie, "START_SPRITE_MODEL", _:START_SPRITE_MODEL);
    TrieSetCell(g_ModelsConfigurationKeysTrie, "END_SPRITE_MODEL", _:END_SPRITE_MODEL);
}

@initMapConfigurationTrie()
{
    g_MapConfigurationKeysTrie = TrieCreate();

    TrieSetCell(g_MapConfigurationKeysTrie, "SHOW_START_SPRITE", _:SHOW_START_SPRITE);
    TrieSetCell(g_MapConfigurationKeysTrie, "SHOW_END_SPRITE", _:SHOW_END_SPRITE);
    TrieSetCell(g_MapConfigurationKeysTrie, "SHOW_TOWER", _:SHOW_TOWER);
    TrieSetCell(g_MapConfigurationKeysTrie, "TOWER_HEALTH", _:TOWER_HEALTH);
    TrieSetCell(g_MapConfigurationKeysTrie, "SHOW_BLAST_ON_MONSTER_TOUCH", _:SHOW_BLAST_ON_MONSTER_TOUCH);
}

@initWavesConfigurationTrie()
{
    g_WavesConfigurationKeysTrie = TrieCreate();

    TrieSetCell(g_MapConfigurationKeysTrie, "Type", _:SHOW_START_SPRITE);
    TrieSetCell(g_MapConfigurationKeysTrie, "Health", _:SHOW_START_SPRITE);
    TrieSetCell(g_MapConfigurationKeysTrie, "Speed", _:SHOW_START_SPRITE);
    TrieSetCell(g_MapConfigurationKeysTrie, "Interval", _:SHOW_START_SPRITE);
    TrieSetCell(g_MapConfigurationKeysTrie, "Num", _:SHOW_START_SPRITE);
    TrieSetCell(g_MapConfigurationKeysTrie, "Delay", _:SHOW_START_SPRITE);
}