#if defined td_json_events_included
    #endinput
#endif
#define td_json_events_included

public registerClientCommands()
{
    register_clcmd("say /start", "@cmdStartWave");
    register_clcmd("say /nextwave", "@cmdSetNextWave");
}

public registerMonsterEvents()
{
    RegisterHam(Ham_Touch, "info_target", "monsterChangeTrack", 0);
}

@cmdStartWave(id)
{
    if(g_ActualWave <= 0)
    {
        g_ActualWave = 1;
    }

    new waveTimeToWave = getWaveTimeToWave(g_ActualWave);

    createCounter(3, "startWaveCounter", "@startWaveCounterChanged", "@startWave");
}

@startWaveCounterChanged(time)
{
    client_print(0, 3, "Wave will start in: %ds", time);
}

@startWave()
{
    client_print(0, 3, "Wave started.");
    startSendingWaveMonsters(g_ActualWave);
}

@cmdSetNextWave(id)
{
    g_ActualWave++;
}
