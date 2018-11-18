#if defined td_engine_monster_types_manager_includes
  #endinput
#endif
#define td_engine_monster_types_manager_includes

new Trie:g_MonsterTypeModelsTrie;
new Trie:g_MonsterTypePluginsTrie;

public register_monster(pluginId, monsterTypeName[33], Array:monsterModelsArray)
{
    TrieSetCell(g_MonsterTypeModelsTrie, monsterTypeName, _:monsterModelsArray);
    TrieSetCell(g_MonsterTypePluginsTrie, monsterTypeName, pluginId);
}

public gerRandomModelOfMonsterType(monsterTypeName[33], model[128])
{
    if(!TrieKeyExists(g_MonsterTypeModelsTrie, monsterTypeName))
    {
        return;
    }

    new Array:monsterModelsArray;
    TrieGetCell(g_MonsterTypeModelsTrie, monsterTypeName, .value = monsterModelsArray);

    new modelsCount = ArraySize(monsterModelsArray);
    ArrayGetString(monsterModelsArray, random(modelsCount), model, charsmax(model));
}

public initMonsterTypeModelsTrie()
{
    g_MonsterTypeModelsTrie = TrieCreate();
    g_MonsterTypePluginsTrie = TrieCreate();
}

public destroyMonsterTypeModelsTrie()
{
    new TrieIter:iterator = TrieIterCreate(g_MonsterTypeModelsTrie);

    while(!TrieIterEnded(iterator))
    {
        new Array:monsterModelsArray;
        TrieIterGetCell(iterator, .value = monsterModelsArray);

        ArrayDestroy(monsterModelsArray);
        TrieIterNext(iterator);
    }

    TrieDestroy(g_MonsterTypeModelsTrie);
    TrieDestroy(g_MonsterTypePluginsTrie);
}