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
}

public registerMonsterEvents()
{
    RegisterHam(Ham_Touch, "info_target", "monsterChangeTrack", 0);

    RegisterHam(Ham_TraceAttack, "info_target", "monsterShotTraceAttack"); // headshot detector
    RegisterHam(Ham_TakeDamage, "info_target", "controlDamageTakenToMonster"); // headshot damage multiplier
    RegisterHam(Ham_TakeDamage, "info_target", "showMonsterTakenDamage", 1); // damage info
    RegisterHam(Ham_TakeDamage, "info_target", "showMonsterBloodEffect", 1); // blood effect

    RegisterHam(Ham_Killed, "info_target", "monsterKilled");
}

@cmdStartWave(id)
{
    startGame();
}