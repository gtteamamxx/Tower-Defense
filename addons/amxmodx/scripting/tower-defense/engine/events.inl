#if defined td_json_events_included
    #endinput
#endif
#define td_json_events_included

public registerClientEvents()
{
    RegisterHamPlayer(Ham_Spawn, "onPlayerSpawn", 1);

    g_SyncHudInfo = CreateHudSyncObj();
}

public registerClientCommands()
{
    register_clcmd("say /start", "@cmdStartWave");
    register_clcmd("say /nextwave", "@cmdSetNextWave");
}

public registerMonsterEvents()
{
    RegisterHam(Ham_Touch, "info_target", "monsterChangeTrack", 0);

    RegisterHam(Ham_TraceAttack, "info_target", "monsterShotTraceAttack");
    RegisterHam(Ham_TakeDamage, "info_target", "controlDamageTakenToMonster");
    RegisterHam(Ham_TakeDamage, "info_target", "showMonsterTakedDamage", 1);
    RegisterHam(Ham_TakeDamage, "info_target", "showMonsterBloodEffect", 1);

    RegisterHam(Ham_Killed, "info_target", "monsterKilled")
}

@cmdStartWave(id)
{
    if(g_ActualWave <= 0)
    {
        g_ActualWave = 1;
    }

    new waveTimeToWave = getWaveTimeToWave(g_ActualWave);

    createCounter(
        .time = 3, 
        .counterKey = "startWaveCounter", 
        .counterChangedFunction = "@startWaveCounterChanged", 
        .counterCompletedFunction = "@startWave"
    );
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
