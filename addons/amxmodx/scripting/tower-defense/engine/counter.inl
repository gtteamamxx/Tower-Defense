#if defined td_json_counter_included
  #endinput
#endif
#define td_json_counter_included

new Trie:g_CounterTrie;

public initCounterTrie()
{
    g_CounterTrie = TrieCreate();
}

stock createCounterTrie(time, counterKey[33], counterChangedFunction[33], counterCompletedFunction[33], Float:delay = 0.1)
{
    if(time <= 0 || TrieKeyExists(g_CounterTrie, counterKey)) 
    {
        return;
    }

    new Array:counterDataArray = ArrayCreate(32);
    ArrayPushCell(counterDataArray, time);
    ArrayPushString(counterDataArray, counterChangedFunction);
    ArrayPushString(counterDataArray, counterCompletedFunction);

    TrieSetCell(g_CounterTrie, counterKey, counterDataArray);

    set_task(delay, "@counterChanged", .parameter = counterKey, .len = 32);
}

@counterChanged(counterKey[33])
{
    if(!TrieKeyExists(g_CounterTrie, counterKey))
    {
        return;
    }

    new Array:counterDataArray; 
    TrieGetCell(g_CounterTrie, counterKey, .value = counterDataArray);

    new remaingTime = ArrayGetCell(counterDataArray, 0);

    if(remaingTime <= 0)
    {
        new counterCompletedFunction[33];
        ArrayGetString(counterDataArray, 2, counterCompletedFunction, .size = 32);

        set_task(0.1, counterCompletedFunction);

        ArrayDestroy(counterDataArray);
        TrieDeleteKey(g_CounterTrie, counterKey);

        return;
    }
    else
    {
        new counterChangedFunction[33];
        ArrayGetString(counterDataArray, 1, counterChangedFunction, .size = 32);

        new functionId = get_func_id(.funcName = counterChangedFunction);
        callfunc_begin_i(functionId);
        callfunc_push_int(remaingTime);
        callfunc_end();
    }

    remaingTime--;
    ArraySetCell(counterDataArray, 0, remaingTime);

    set_task(1.0, "@counterChanged", .parameter = counterKey, .len = 32);
}

public destroyCounterTrie()
{
    TrieDestroy(g_CounterTrie);
}