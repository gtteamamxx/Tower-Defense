#if defined _towerdefense_turrets_forwards_included
  #endinput
#endif
#define _towerdefense_turrets_forwards_included

public executeOnTurretCreatedForward(pluginId, ent, id)
{
    new forwardId = CreateOneForward(pluginId, "td_on_turret_created", FP_CELL, FP_CELL);

    new ret;
    ExecuteForward(forwardId, ret, ent, id);

    DestroyForward(forwardId);
}