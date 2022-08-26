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