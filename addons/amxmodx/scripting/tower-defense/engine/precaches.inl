#if defined td_engine_precaches_includes
  #endinput
#endif
#define td_engine_precaches_includes

public plugin_precache()
{
    @initTries();
    @initArrays();

    loadModelsConfiguration();
    @precacheModels();

    loadSoundsConfiguration();
    @precacheSounds();
}

public releaseArrays()
{
    @releaseArrays();
}

public relaseTries()
{
    @releaseTries();
}

@precacheModels()
{
    for(new i = 0; i < _:MODELS_ENUM; ++i)
    {
        new id = precache_model(g_Models[MODELS_ENUM:i]);

        ArrayPushCell(g_ModelsPrecacheIdArray, id);
    }
}

@precacheSounds()
{
    for(new i = 0; i < _:SOUND_ENUM; ++i)
    {
        new Array:soundPathsArray = Array:ArrayGetCell(g_SoundsConfigurationPathsArray, i);

        for(new j = 0; j < ArraySize(soundPathsArray); ++j) 
        {
            new soundPath[128];
            ArrayGetString(soundPathsArray, j, soundPath, 127);

            precache_sound(soundPath);
        }
    }
}

@releaseArrays()
{
    @releaseModelsPrecacheArray();
    @releaseWaveDataArray();
    @releaseMonsterEntArray();
    @releaseSoundsArray();
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
    @initSoundsConfigurationTrie();

    initCounterTrie();
    initMonsterTypesManagerTries();
}

@initArrays()
{
    @initWaveDataArray();
    @initMonstersEntArray();
    @initSoundsArray();
}

@initMonstersEntArray()
{
    g_MonstersEntArray = ArrayCreate();
}

@initWaveDataArray()
{
    g_WaveDataArray = ArrayCreate();
}

@initSoundsArray()
{
    g_SoundsConfigurationPathsArray = ArrayCreate();

    // fill array with empty arrays which'll contain sounds paths
    for(new i = 0; i < _:SOUND_ENUM; ++i)
    {
        new Array:soundsArray = ArrayCreate(128);
        ArrayPushCell(g_SoundsConfigurationPathsArray, soundsArray);
    }
}

@initModelsConfigurationTrie()
{
    g_ModelsConfigurationKeysTrie = TrieCreate();
    g_ModelsPrecacheIdArray = ArrayCreate();

    TrieSetCell(g_ModelsConfigurationKeysTrie, "TOWER_MODEL", _:TOWER_MODEL);
    TrieSetCell(g_ModelsConfigurationKeysTrie, "START_SPRITE_MODEL", _:START_SPRITE_MODEL);
    TrieSetCell(g_ModelsConfigurationKeysTrie, "END_SPRITE_MODEL", _:END_SPRITE_MODEL);
    TrieSetCell(g_ModelsConfigurationKeysTrie, "HEALTHBAR_SPRITE_MODEL", _:HEALTHBAR_SPRITE_MODEL);
    TrieSetCell(g_ModelsConfigurationKeysTrie, "BLOOD_SPRITE_MODEL", _:BLOOD_SPRITE_MODEL);
    TrieSetCell(g_ModelsConfigurationKeysTrie, "BLOODSPRAY_SPRITE_MODEL", _:BLOODSPRAY_SPRITE_MODEL);
    TrieSetCell(g_ModelsConfigurationKeysTrie, "EXPLODE_SPRITE_MODEL", _:EXPLODE_SPRITE_MODEL);
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

@initSoundsConfigurationTrie()
{
    g_SoundsConfigurationKeysTrie = TrieCreate();

    TrieSetCell(g_SoundsConfigurationKeysTrie, "WAVE_COUNTDOWN", _:WAVE_COUNTDOWN);
    TrieSetCell(g_SoundsConfigurationKeysTrie, "WAVE_CLEAR", _:WAVE_CLEAR);
    TrieSetCell(g_SoundsConfigurationKeysTrie, "WAVE_START", _:WAVE_START);
    TrieSetCell(g_SoundsConfigurationKeysTrie, "LOSE", _:LOSE);
    TrieSetCell(g_SoundsConfigurationKeysTrie, "WIN", _:WIN);
    TrieSetCell(g_SoundsConfigurationKeysTrie, "MONSTER_DIE", _:MONSTER_DIE);
    TrieSetCell(g_SoundsConfigurationKeysTrie, "MONSTER_GROWL", _:MONSTER_GROWL);
    TrieSetCell(g_SoundsConfigurationKeysTrie, "MONSTER_HIT", _:MONSTER_HIT);
    TrieSetCell(g_SoundsConfigurationKeysTrie, "MONSTER_SOUND", _:MONSTER_SOUND);
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
    TrieSetCell(g_MonsterTypesConfigurationKeysTrie, "TowerDamage", _:MONSTER_TOWER_DAMAGE);

    g_WavesConfigurationKeysTrie = TrieCreate();

    TrieSetCell(g_WavesConfigurationKeysTrie, "TimeToWave", _:WAVE_TIME_TO_WAVE);
}

@releaseModelsPrecacheArray() 
{
    ArrayDestroy(g_ModelsPrecacheIdArray);
}

@releaseWaveDataArray()
{
    new size = ArraySize(g_WaveDataArray);

    for(new i = 0; i < size; ++i)
    {
        new Array:waveArray = Array:ArrayGetCell(g_WaveDataArray, i);

        new Trie:waveConfigurationTrie = Trie:ArrayGetCell(waveArray, _:WAVE_CONFIG);
        new Array:monsterTypesArray = Array:ArrayGetCell(waveArray, _:WAVE_MONSTER_TYPES);
        new Array:monstersCountArray = Array:ArrayGetCell(waveArray, _:WAVE_MONSTERS_COUNT);

        new monsterTypesCount = ArraySize(monsterTypesArray);
        for(new j = 0; j < monsterTypesCount; ++j)
        {
            new Trie:monsterTypeTrie = Trie:ArrayGetCell(monsterTypesArray, j);
            TrieDestroy(monsterTypeTrie);
        }

        TrieDestroy(waveConfigurationTrie);

        ArrayDestroy(monsterTypesArray);
        ArrayDestroy(monstersCountArray);

        ArrayDestroy(waveArray);
    }

    ArrayDestroy(g_WaveDataArray);
}

@releaseMonsterEntArray()
{
    ArrayDestroy(g_MonstersEntArray);
}

@releaseSoundsArray()
{
    for(new i = 0; i < _:SOUND_ENUM; ++i)
    {
        new Array:soundPathsArray = Array:ArrayGetCell(g_SoundsConfigurationPathsArray, i);
        ArrayDestroy(soundPathsArray);
    }

    ArrayDestroy(g_SoundsConfigurationPathsArray);
}