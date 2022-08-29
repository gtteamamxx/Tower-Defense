#if defined _towerdefense_turrets_forwards_included
  #endinput
#endif
#define _towerdefense_turrets_forwards_included

public executeOnTurretCreatedForward(pluginId, ent, id)
{
    // create callback pointer
    new forwardId = CreateOneForward(pluginId, "td_on_turret_created", FP_CELL, FP_CELL);

    // execute
    new ret;
    ExecuteForward(forwardId, ret, ent, id);

    // free memory
    DestroyForward(forwardId);
}

public executeOnTurretLowAmmoForward(pluginId, ent, id)
{
    // create callback pointer
    new forwardId = CreateOneForward(pluginId, "td_on_turret_low_ammo", FP_CELL, FP_CELL);

    // execute
    new ret;
    ExecuteForward(forwardId, ret, ent, id);

    // free memory
    DestroyForward(forwardId);
}

public executeOnTurretStartFireForward(pluginId, ent, monster, id)
{
    // create callback pointer
    new forwardId = CreateOneForward(pluginId, "td_on_turret_start_fire", FP_CELL, FP_CELL, FP_CELL);

    // execute
    new ret;
    ExecuteForward(forwardId, ret, ent, monster, id);

    // free memory
    DestroyForward(forwardId);
}

public executeOnTurretStopFireForward(pluginId, ent, id)
{
    // create callback pointer
    new forwardId = CreateOneForward(pluginId, "td_on_turret_stop_fire", FP_CELL, FP_CELL);

    // execute
    new ret;
    ExecuteForward(forwardId, ret, ent, id);

    // free memory
    DestroyForward(forwardId);
}


public executeOnTurretNoAmmoForward(pluginId, ent, id)
{
    // create callback pointer
    new forwardId = CreateOneForward(pluginId, "td_on_turret_no_ammo", FP_CELL, FP_CELL);

    // execute
    new ret;
    ExecuteForward(forwardId, ret, ent, id);

    // free memory
    DestroyForward(forwardId);
}

public executeOnTurretShotForward(pluginId, ent, monster, id, Float:damage)
{
    // create callback pointer
    new forwardId = CreateOneForward(pluginId, "td_on_turret_shot", FP_CELL, FP_CELL, FP_CELL, FP_FLOAT);

    // execute
    new ret;
    ExecuteForward(forwardId, ret, ent, monster, id, damage);

    // free memory
    DestroyForward(forwardId);
}

public executeOnTurretShotMissForward(pluginId, ent, monster, id)
{
        // create callback pointer
    new forwardId = CreateOneForward(pluginId, "td_on_turret_shot_miss", FP_CELL, FP_CELL, FP_CELL);

    // execute
    new ret;
    ExecuteForward(forwardId, ret, ent, monster, id);

    // free memory
    DestroyForward(forwardId);
}