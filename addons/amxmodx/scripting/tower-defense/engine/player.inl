#if defined td_engine_player_includes
  #endinput
#endif
#define td_engine_player_includes

new g_SyncHudInfo;

public onPlayerKilledMonster(playerId, bool:isByHeadshot, bool:isKilledByPlayer)
{
    addPlayerFrags(playerId, .amount = 1);

    createPlayerKilledIcon(playerId, isByHeadshot, isKilledByPlayer);
}

public onPlayerSpawn(playerId)
{
    @showPlayerHudIfAlive(playerId);
}

@showPlayerHudIfAlive(playerId)
{
    if (!is_user_alive(playerId)) 
    {
        return;
    }

    static maxWaveNumber; if (!maxWaveNumber) maxWaveNumber = getMaxWaveNumber();
    static mapMaxTowerHealth; if (!mapMaxTowerHealth) mapMaxTowerHealth = getMapConfigurationData(TOWER_HEALTH);
    new monstersForWave = getTotalNumberOfMonstersToSendForWave(g_ActualWave);

    set_hudmessage(255, 255, 255, 0.1, 0.05, 0, 6.0, 2.1, 0.0, 0.1);
    ShowSyncHudMsg(
        playerId, 
        g_SyncHudInfo, 
        "[WAVE: %d / %d]^n[MONSTERS: %d (%d) / %d] [TOWER: %d / %d]",
        g_ActualWave,
        maxWaveNumber,
        g_AliveMonstersNum,
        g_SentMonsters,
        monstersForWave,
        g_TowerHealth,
        mapMaxTowerHealth
    );

    set_task(2.0, "@showPlayerHudIfAlive", playerId);
}