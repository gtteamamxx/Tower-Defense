#if defined td_json_events_included
    #endinput
#endif
#define td_json_events_included

public registerClientCommands()
{
    register_clcmd("say /start", "@test");
    register_clcmd("say /nextwave", "@test2");
}

@test(id)
{
    createCounterTrie(20, "testKey", "@testChanged", "@testCompleted");
}

@testChanged(time)
{
    client_print(0, 3, "remaing: %d", time);
}

@testCompleted()
{
    client_print(0, 3, "finished");
}

@test2(id)
{
    g_ActualWave++;
}
