#if defined td_json_counter_included
  #endinput
#endif
#define td_json_counter_included

new Trie:g_CounterTrie;

enum DATA_ARRAY
{
    TIME,
    CHANGED_FUNCTION,
    COMPLETED_FUNCTION,
    CUSTOM_CELL
}

public initCounterTrie()
{
    g_CounterTrie = TrieCreate();
}

stock createCounter(time, counterKey[33], counterChangedFunction[33], counterCompletedFunction[33], Float:delay = 0.1, customInfo = 0)
{
    if(time <= 0 || TrieKeyExists(g_CounterTrie, counterKey)) 
    {
        return;
    }

    new Array:counterDataArray = ArrayCreate(64);
    ArrayPushCell(counterDataArray, time);
    ArrayPushString(counterDataArray, counterChangedFunction);
    ArrayPushString(counterDataArray, counterCompletedFunction);
    ArrayPushCell(counterDataArray, customInfo);

    TrieSetCell(g_CounterTrie, counterKey, counterDataArray);

    set_task(delay, "@counterChanged", .parameter = counterKey, .len = 32);
}

stock isCounterExists(counterKey[33])
{
    return TrieKeyExists(g_CounterTrie, counterKey);
}

stock removeCounter(counterKey[33])
{
    if(!TrieKeyExists(g_CounterTrie, counterKey))
    {
        return;
    }
        
    new Array:counterDataArray; 
    TrieGetCell(g_CounterTrie, counterKey, .value = counterDataArray);
    
    ArrayDestroy(counterDataArray);
    TrieDeleteKey(g_CounterTrie, counterKey);
}

@counterChanged(counterKey[33])
{
    if(!TrieKeyExists(g_CounterTrie, counterKey))
    {
        return;
    }

    new Array:counterDataArray; 
    TrieGetCell(g_CounterTrie, counterKey, .value = counterDataArray);

    new remaingTime = ArrayGetCell(counterDataArray, _:TIME);

    if(remaingTime <= 0)
    {
        new counterCompletedFunction[33];
        ArrayGetString(counterDataArray, _:COMPLETED_FUNCTION, counterCompletedFunction, .size = 32);

        new customInfo = ArrayGetCell(counterDataArray, _:CUSTOM_CELL);

        new functionId = get_func_id(.funcName = counterCompletedFunction);
        callfunc_begin_i(functionId);
        callfunc_push_int(customInfo);
        callfunc_push_str(counterKey);
        callfunc_end();

        removeCounter(counterKey);
    }
    else
    {
        new counterChangedFunction[33];
        ArrayGetString(counterDataArray, _:CHANGED_FUNCTION, counterChangedFunction, .size = 32);

        new customInfo = ArrayGetCell(counterDataArray, _:CUSTOM_CELL);

        new functionId = get_func_id(.funcName = counterChangedFunction);
        callfunc_begin_i(functionId);
        callfunc_push_int(remaingTime);
        callfunc_push_int(customInfo);
        callfunc_end();

        remaingTime--;
        ArraySetCell(counterDataArray, _:TIME, remaingTime);

        set_task(1.0, "@counterChanged", .parameter = counterKey, .len = 32);
    }
}

public destroyCounterTrie()
{
    TrieDestroy(g_CounterTrie);
}