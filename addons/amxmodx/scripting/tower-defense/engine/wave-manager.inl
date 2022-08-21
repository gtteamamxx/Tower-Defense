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
        TrieGetArray(monsterTypeTrie, keyToString(_:MONSTER_COUNT), count, 2);
        totalCount[0] += count[0];
        totalCount[1] += count[1];
    }

    return true;
}

public Float:getRandomValueForMonsterTypeInWave(wave, monsterTypeIndex, WAVE_MONSTER_DATA_ENUM:key)
{
    if(!@isWaveValid(wave) || monsterTypeIndex < 0)
    {
        return 0.0;
    }

    new Trie:monsterTypeTrie = @getMonsterTypeTrie(wave, monsterTypeIndex);

    new Float:value[2];
    TrieGetArray(monsterTypeTrie, keyToString(_:key), value, 2);
    return value[1] == 0.0 ? value[0] : random_float(value[0], value[1]);
}

public getMonsterTypeNameForMonsterTypeInWave(wave, monsterTypeIndex, monsterTypeName[33])
{
    if(!@isWaveValid(wave) || monsterTypeIndex < 0)
    {
        return;
    }

    new Trie:monsterTypeTrie = @getMonsterTypeTrie(wave, monsterTypeIndex);
    TrieGetString(monsterTypeTrie, keyToString(_:MONSTER_TYPE), monsterTypeName, charsmax(monsterTypeName));
}

public getNumberOfMonstersForMonsterTypeInWave(wave, monsterTypeIndex)
{
    if(!@isWaveValid(wave) || monsterTypeIndex < 0)
    {
        return -1;
    }

    new Trie:monsterTypeTrie = @getMonsterTypeTrie(wave, monsterTypeIndex);

    new count[2];
    TrieGetArray(monsterTypeTrie, keyToString(_:MONSTER_COUNT), count, 2);

    return count[1] == 0 ? count[0] : random_num(count[0], count[1]);
}

public getDamageWhichMonsterWillTakeForTowerForMonsterTypeInWave(wave, monsterTypeIndex)
{
    if(!@isWaveValid(wave) || monsterTypeIndex < 0)
    {
        return -1;
    }

    new Trie:monsterTypeTrie = @getMonsterTypeTrie(wave, monsterTypeIndex);

    new count[2];
    TrieGetArray(monsterTypeTrie, keyToString(_:MONSTER_TOWER_DAMAGE), count, 2);
    return count[1] == 0 ? count[0] : random_num(count[0], count[1]);
}


public getWaveTimeToWave(wave)
{
    if(!@isWaveValid(wave))
    {
        return -1;
    }

    new Trie:waveConfigurationTrie = @getWaveConfigurationTrie(wave);
    new timeToWave = -1;
    TrieGetCell(waveConfigurationTrie, keyToString(_:WAVE_TIME_TO_WAVE), .value = timeToWave);
    return timeToWave;
}

public getWaveMonsterTypesNum(wave)
{
    if(!@isWaveValid(wave))
    {
        return -1;
    }

    new Array:monsterTypesArray = @getWaveMonsterTypesArray(wave);

    return ArraySize(monsterTypesArray);
}

getMaxWaveNumber() 
{
    new maxWaveNumber = ArraySize(g_WaveDataArray) + 1;
    return maxWaveNumber;
}

@isWaveValid(wave)
{
    new maxWaveNumber = getMaxWaveNumber();
    return 1 <= wave <= maxWaveNumber;
}

Trie:@getWaveConfigurationTrie(wave)
{
    new Array:waveArray = @getWaveArray(wave);
    return Trie:ArrayGetCell(waveArray, _:WAVE_CONFIG);
}

Array:@getWaveArray(wave)
{
    return Array:ArrayGetCell(g_WaveDataArray, wave - 1);
}

Array:@getWaveMonsterTypesArray(wave)
{
    new Array:waveArray = @getWaveArray(wave);
    return Array:ArrayGetCell(waveArray, _:WAVE_MONSTER_TYPES);
}

Trie:@getMonsterTypeTrieFromMonsterTypesArray(Array:monsterTypesArray, monsterTypeIndex)
{
    return Trie:ArrayGetCell(monsterTypesArray, monsterTypeIndex);
}

Trie:@getMonsterTypeTrie(wave, monsterTypeIndex)
{
    new Array:waveMonsterTypesArray = @getWaveMonsterTypesArray(wave);

    return Trie:@getMonsterTypeTrieFromMonsterTypesArray(
            .monsterTypesArray = waveMonsterTypesArray,
            .monsterTypeIndex = monsterTypeIndex
    );
}
