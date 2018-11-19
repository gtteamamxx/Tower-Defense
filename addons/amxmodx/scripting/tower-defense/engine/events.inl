#if defined td_json_events_included
    #endinput
#endif
#define td_json_events_included

public registerClientCommands()
{
    register_clcmd("say /start", "@test");
    register_clcmd("say /nextwave", "@test2");
}

public registerMonsterEvents()
{
    RegisterHam(Ham_Touch, "info_target", "monsterChangeTrack", 0);
}

@test(id)
{
    if(g_ActualWave <= 0)
    {
        g_ActualWave = 1;
    }

    new waveTimeToWave = getWaveTimeToWave(g_ActualWave);
    createCounter(waveTimeToWave, "testKey", "@testChanged", "@testCompleted");
}

@testChanged(time)
{
    client_print(0, 3, "Wave will start in: %ds", time);
}

@testCompleted()
{
    client_print(0, 3, "Wave is starting...");
    startSendingWaveMonsters(g_ActualWave);
}

@test2(id)
{
    g_ActualWave++;
}
