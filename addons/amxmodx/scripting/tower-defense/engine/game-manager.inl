#if defined td_json_game_manager_included
    #endinput
#endif
#define td_json_game_manager_included

public startGame()
{
    if (g_ActualWave > 0)
    {
        log_amx("Unable to start game. Already started.");
        return;
    }

    startNextWave();
}

public checkIfWaveIsCompleted()
{
    // next wave should start
    // when all monsters were send
    // and all monsters all killed
    new bool:isWaveFinished = areAllMonstersKilledInCurrentWave();

    if (isWaveFinished)
    {
        executeOnWaveEndForward(g_ActualWave);

        new bool:isEndGame = checkIfItsEndGame();

        // if it's end game we shouldn't start new wave
        if (isEndGame)
        {
            client_print(0, 3, "Congratulations. End Game!");
            return;
        }

        startNextWave();
    }
}

public startNextWave()
{
    g_ActualWave++;
    g_SentMonsters = 0;

    set_hudmessage(212, 255, 255, 0.14, 0.57, 0, 3.0, 5.1)
    show_hudmessage(0, "Get ready for wave %d!", g_ActualWave);

    new waveTimeToWave = getWaveTimeToWave(g_ActualWave);

    playSoundGlobalRandom(WAVE_CLEAR);

    createCounter(
        .time = waveTimeToWave, 
        .counterKey = "startWaveCounter", 
        .counterChangedFunction = "@startWaveCounterChanged", 
        .counterCompletedFunction = "@startWave",
        .delay = 5.0
    );
}

@startWaveCounterChanged(time)
{
    set_hudmessage(212, 255, 255, 0.14, 0.57, 0, 3.0, 1.05)
    show_hudmessage(0, "Wave %d will start in: %ds", g_ActualWave, time);

    playSoundGlobalRandom(WAVE_COUNTDOWN);
}

@startWave()
{
    set_hudmessage(212, 255, 255, 0.14, 0.57, 0, 6.0, 5.0)
    show_hudmessage(0, "Wave started!");

    playSoundGlobalRandom(WAVE_START);

    startSendingWaveMonsters(g_ActualWave);
}