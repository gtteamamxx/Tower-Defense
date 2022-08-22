#if defined td_json_end_game_manager_included
    #endinput
#endif
#define td_json_end_game_manager_included

public bool:checkIfItsEndGame()
{
    // If game hasn't started yet
    if (g_ActualWave < 0)
    {
        return false;
    }

    new maxWaveNumber = getMaxWaveNumber();
    new bool:isLastWave = g_ActualWave == maxWaveNumber;
    new bool:areAllMonstersKilled = areAllMonstersKilledInCurrentWave();

    // if tower was destroyed then monsters won
    if (g_TowerHealth <= 0)
    {
        @endGame();
        return true;
    }
    // if players killed all monsters then players have win
    else if (isLastWave && areAllMonstersKilled) 
    {
        @endGame();
        return true;
    }

    return false;
}

@endGame()
{
    executeOnGameEndForward();

    @stopAllMonsters();
    @stopSendingNewMonsters();
}

@stopAllMonsters()
{
    for(new i = 0; i < ArraySize(g_MonstersEntArray); ++i)
    {
        new monsterEntity = ArrayGetCell(g_MonstersEntArray, i);

        if (isMonster(monsterEntity))
        {
            removeMonsterHealthbar(monsterEntity);
            
            entity_set_float(monsterEntity,	EV_FL_health, 0.0);
            entity_set_float(monsterEntity,	EV_FL_nextthink, 0.0);
            entity_set_int(monsterEntity, EV_INT_solid, SOLID_NOT);
            entity_set_int(monsterEntity, EV_INT_sequence, 1); // idle animation
            entity_set_float(monsterEntity, EV_FL_framerate, 1.0); 	
            entity_set_vector(monsterEntity, EV_VEC_velocity, Float:{0.0, 0.0, 0.0});
        }
    }
}

@stopSendingNewMonsters()
{
    remove_task(SEND_MONSTER_TASK);
}
