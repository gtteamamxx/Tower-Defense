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
    if(g_ActualWave <= 0)
    {
        g_ActualWave = 1;
    }

    new waveTimeToWave = getWaveTimeToWave(g_ActualWave);
    client_print(0,3, "wave: %d, timeToWave: %d", g_ActualWave, waveTimeToWave);
    createCounter(2, "testKey", "@testChanged", "@testCompleted");
}

@testChanged(time)
{
    client_print(0, 3, "remaing: %d", time);
}

@testCompleted()
{
    client_print(0, 3, "finished");
    startSendingWaveMonsters(g_ActualWave);
}

@test2(id)
{
    g_ActualWave++;
}
