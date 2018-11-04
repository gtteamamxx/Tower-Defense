#if defined td_engine_precaches_includes
  #endinput
#endif
#define td_engine_precaches_includes

public plugin_precache()
{
    @initTries();
    @initArrays();

    loadModelsConfiguration();

    for(new i = 0; i < _:MODELS_ENUM; ++i)
    {
        precache_model(g_Models[MODELS_ENUM:i]);
    }
}

public releaseArrays()
{
    @releaseArrays();
}

@releaseArrays()
{
    @releaseWaveDataArray();
}

@initTries()
{
    @initMapConfigurationTrie();
    @initModelsConfigurationTrie();
    @initWavesConfigurationTrie();
}

@initArrays()
{
    @initWaveDataArray();
}

@initWaveDataArray()
{
    g_WaveDataArray = ArrayCreate();
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

    TrieSetCell(g_WavesConfigurationKeysTrie, "Type", _:TYPE);
    TrieSetCell(g_WavesConfigurationKeysTrie, "Health", _:HEALTH);
    TrieSetCell(g_WavesConfigurationKeysTrie, "Speed", _:SPEED);
    TrieSetCell(g_WavesConfigurationKeysTrie, "DeployInterval", _:DEPLOY_INTERVAL);
    TrieSetCell(g_WavesConfigurationKeysTrie, "Count", _:COUNT);
    TrieSetCell(g_WavesConfigurationKeysTrie, "DeployExtraDelay", _:DEPLOY_EXTRA_DELAY);
}

@releaseWaveDataArray()
{
    new size = ArraySize(g_WaveDataArray);
    if(size != 0)
    {
        for(new i = 0; i < size; ++i)
        {
            new Array:waveArray = Array:ArrayGetCell(g_WaveDataArray, i);
            new waveArraySize = ArraySize(waveArray);

            for(new j = 0; j < waveArraySize; ++j)
            {
                new Trie:monsterTypeTrie = Trie:ArrayGetCell(waveArray, j);
                TrieDestroy(monsterTypeTrie);
            }

            ArrayDestroy(waveArray);
        }
    }

    ArrayDestroy(g_WaveDataArray);
}