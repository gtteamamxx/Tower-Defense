#if defined td_json_wave_manager_included
  #endinput
#endif
#define td_json_wave_manager_included

new g_ActualWave;

public bool:getWaveMonstersTotalCount(wave, totalCount[2])
{
    if(!@isWaveValid(wave))
    {
        return false;
    }

    new Array:waveMonsterTypesArray = @getWaveMonsterTypesArray(wave);

    new monsterTypesCount = ArraySize(waveMonsterTypesArray);

    for(new i = 0; i < monsterTypesCount; i++)
    {
        new Trie:monsterTypeTrie = Trie:@getMonsterTypeTrieFromMonsterTypesArray(
            .monsterTypesArray = waveMonsterTypesArray,
            .monsterTypeIndex = i
        );

        new count[2];
        TrieGetArray(monsterTypeTrie, @keyToString(_:COUNT), count, 2);
        totalCount[0] += count[0];
        totalCount[1] += count[1];
    }

    return true;
}

@isWaveValid(wave)
{
    new maxWaveNumber = ArraySize(g_WaveDataArray) + 1;
    return 1 <= wave <= maxWaveNumber;
}

Array:@getWaveArray(wave)
{
    return Array:ArrayGetCell(g_WaveDataArray, wave - 1);
}

Array:@getWaveMonsterTypesArray(wave)
{
    new Array:waveArray = @getWaveArray(wave);
    return Array:ArrayGetCell(waveArray, _:MONSTER_TYPES);
}

Trie:@getMonsterTypeTrieFromMonsterTypesArray(Array:monsterTypesArray, monsterTypeIndex)
{
    return Trie:ArrayGetCell(monsterTypesArray, monsterTypeIndex);
}

@keyToString(keyIndex)
{
    new key[4];
    num_to_str(keyIndex, key, charsmax(key));
    return key;
}