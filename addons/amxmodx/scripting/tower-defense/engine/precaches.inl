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

public relaseTries()
{
    @releaseTries();
}

@releaseArrays()
{
    @releaseWaveDataArray();
}

@releaseTries()
{
    destroyCounterTrie();
    destroyMonsterTypesManagerTries();
}

@initTries()
{
    @initMapConfigurationTrie();
    @initModelsConfigurationTrie();
    @initWavesConfigurationTrie();

    initCounterTrie();
    initMonsterTypesManagerTries();
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
    TrieSetCell(g_ModelsConfigurationKeysTrie, "HEALTHBAR_SPRITE_MODEL", _:HEALTHBAR_SPRITE_MODEL);
}

@initMapConfigurationTrie()
{
    g_MapConfigurationKeysTrie = TrieCreate();

    TrieSetCell(g_MapConfigurationKeysTrie, "SHOW_START_SPRITE", _:SHOW_START_SPRITE);
    TrieSetCell(g_MapConfigurationKeysTrie, "SHOW_END_SPRITE", _:SHOW_END_SPRITE);
    TrieSetCell(g_MapConfigurationKeysTrie, "SHOW_TOWER", _:SHOW_TOWER);
    TrieSetCell(g_MapConfigurationKeysTrie, "TOWER_HEALTH", _:TOWER_HEALTH);
    TrieSetCell(g_MapConfigurationKeysTrie, "SHOW_BLAST_ON_MONSTER_TOUCH", _:SHOW_BLAST_ON_MONSTER_TOUCH);
    TrieSetCell(g_MapConfigurationKeysTrie, "TIME_TO_WAVE", _:MAP_TIME_TO_WAVE);
}

@initWavesConfigurationTrie()
{
    g_MonsterTypesConfigurationKeysTrie = TrieCreate();

    TrieSetCell(g_MonsterTypesConfigurationKeysTrie, "Type", _:MONSTER_TYPE);
    TrieSetCell(g_MonsterTypesConfigurationKeysTrie, "Health", _:MONSTER_HEALTH);
    TrieSetCell(g_MonsterTypesConfigurationKeysTrie, "Speed", _:MONSTER_SPEED);
    TrieSetCell(g_MonsterTypesConfigurationKeysTrie, "DeployInterval", _:MONSTER_DEPLOY_INTERVAL);
    TrieSetCell(g_MonsterTypesConfigurationKeysTrie, "Count", _:MONSTER_COUNT);
    TrieSetCell(g_MonsterTypesConfigurationKeysTrie, "DeployExtraDelay", _:MONSTER_DEPLOY_EXTRA_DELAY);

    g_WavesConfigurationKeysTrie = TrieCreate();

    TrieSetCell(g_WavesConfigurationKeysTrie, "TimeToWave", _:WAVE_TIME_TO_WAVE);
}

@releaseWaveDataArray()
{
    new size = ArraySize(g_WaveDataArray);

    for(new i = 0; i < size; ++i)
    {
        new Array:waveArray = Array:ArrayGetCell(g_WaveDataArray, i);

        new Trie:waveConfigurationTrie = Trie:ArrayGetCell(waveArray, _:WAVE_CONFIG);
        new Array:monsterTypesArray = Array:ArrayGetCell(waveArray, _:WAVE_MONSTER_TYPES);

        new monsterTypesCount = ArraySize(monsterTypesArray);
        for(new j = 0; j < monsterTypesCount; ++j)
        {
            new Trie:monsterTypeTrie = Trie:ArrayGetCell(monsterTypesArray, j);
            TrieDestroy(monsterTypeTrie);
        }

        ArrayDestroy(monsterTypesArray);
        TrieDestroy(waveConfigurationTrie);
        ArrayDestroy(waveArray);
    }

    ArrayDestroy(g_WaveDataArray);
}