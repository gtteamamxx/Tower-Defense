#if defined td_json_monsters_manager_included
  #endinput
#endif
#define td_json_monsters_manager_included

public startSendingWaveMonsters(wave)
{
    new monsterTypesNum = getWaveMonsterTypesNum(wave);

    client_print(0, 3, "Monster types num for wave %d: %d", wave, monsterTypesNum);

    @startSendingsendWaveMonsters(wave, .monsterTypeIndex = 0);
}

@startSendingsendWaveMonsters(wave, monsterTypeIndex)
{
    new monsterTypeName[33];
    new count = getNumberOfMonstersForMonsterTypeInWave(wave, monsterTypeIndex);
    new Float:delay = getRandomValueForMonsterTypeInWave(wave, monsterTypeIndex, DEPLOY_EXTRA_DELAY);
    if(delay == -1.0)
    {
        delay == 0.0;
    }

    getMonsterTypeNameForMonsterTypeInWave(wave, monsterTypeIndex, monsterTypeName);
    client_print(0, 3, "Sending %d monster of type: %s. Waiting: %0.1fs", count, monsterTypeName, delay);

    new sendWaveMonsterParameter[3];
    sendWaveMonsterParameter[0] = wave;
    sendWaveMonsterParameter[1] = monsterTypeIndex;
    sendWaveMonsterParameter[2] = count;

    set_task(delay, "@sendMonsterAndAfterSendNextOne", .parameter = sendWaveMonsterParameter, .len = 3);
}

@sendMonsterAndAfterSendNextOne(sendWaveMonsterParameter[3])
{
    new wave = sendWaveMonsterParameter[0];
    new monsterTypeIndex = sendWaveMonsterParameter[1];
    new monstersLeft = sendWaveMonsterParameter[2];

    if(monstersLeft == 0)
    {
        if(monsterTypeIndex + 1 < getWaveMonsterTypesNum(wave))
        {
            @startSendingsendWaveMonsters(wave, monsterTypeIndex + 1);
        }
        return;
    }

    new Float:monsterHealth = getRandomValueForMonsterTypeInWave(wave, monsterTypeIndex, HEALTH);
    new Float:monsterSpeed = getRandomValueForMonsterTypeInWave(wave, monsterTypeIndex, SPEED);
    new Float:deployInterval = getRandomValueForMonsterTypeInWave(wave, monsterTypeIndex, DEPLOY_INTERVAL);

    new Float:sendMonsterParameter[2];
    sendMonsterParameter[0] = monsterHealth;
    sendMonsterParameter[1] = monsterSpeed;

    client_print(0, 3, "Monsters left: %d Waiting: %0.1f", monstersLeft, deployInterval);
    set_task(deployInterval, "@sendMonster", .parameter = sendMonsterParameter, .len = 2);

    sendWaveMonsterParameter[2] = monstersLeft - 1;
    set_task(deployInterval, "@sendMonsterAndAfterSendNextOne", .parameter = sendWaveMonsterParameter, .len = 3);
}

@sendMonster(Float:sendMonsterParameter[2])
{
    new Float:monsterHealth = sendMonsterParameter[0];
    new Float:monsterSpeed = sendMonsterParameter[1];

    client_print(0, 3, "monste sending: hp: %0.1f speed: %0.1f", monsterHealth, monsterSpeed);
}