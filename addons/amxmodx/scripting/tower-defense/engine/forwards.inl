#if defined td_engine_forwards_includes
  #endinput
#endif
#define td_engine_forwards_includes

new g_ForwardOnConfigurationLoad;
new g_ForwardOnGameEnd;
new g_ForwardOnWaveEnd;
new g_ForwardOnMonsterKilled;
new g_ForwardTakeDamage;

public registerForwards()
{
    g_ForwardOnConfigurationLoad = CreateMultiForward("td_on_configuration_load", ET_IGNORE, FP_ARRAY, FP_CELL);
    g_ForwardOnGameEnd = CreateMultiForward("td_on_game_end", ET_IGNORE);
    g_ForwardOnWaveEnd = CreateMultiForward("td_on_wave_end", ET_IGNORE, FP_CELL);
    g_ForwardOnMonsterKilled = CreateMultiForward("td_on_monster_killed", ET_IGNORE, FP_CELL, FP_CELL);
    g_ForwardTakeDamage = CreateMultiForward("td_on_damage_taken_to_monster", ET_CONTINUE, FP_CELL, FP_CELL,  FP_FLOAT);
}

public executeOnGameEndForward()
{
    new iRet;
    ExecuteForward(g_ForwardOnGameEnd, iRet);
}

public executeOnDamageTakenToMonsterForward(monsterEntity, playerId, Float:fDamage)
{
    new iRet;
    ExecuteForward(g_ForwardTakeDamage, iRet, monsterEntity, playerId, fDamage);
}

public executeOnMonsterKilledForward(monsterEntity, playerId)
{
    new iRet;
    ExecuteForward(g_ForwardOnMonsterKilled, iRet, monsterEntity, playerId);
}

public executeOnWaveEndForward(wave)
{
    new iRet;
    ExecuteForward(g_ForwardOnWaveEnd, iRet, wave);
}

public executeOnConfigurationLoadForward(configurationFilePath[128], bool:isGamePossible)
{
    new iRet;
    ExecuteForward(
        g_ForwardOnConfigurationLoad, 
        iRet, 
        PrepareArray(configurationFilePath, charsmax(configurationFilePath), 0), 
        isGamePossible
    );
}