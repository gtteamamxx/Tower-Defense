#if defined _towerdefense_turrets_turret_think_included
  #endinput
#endif
#define _towerdefense_turrets_turret_think_included

public registerTurretThink()
{
    register_think(TURRET_CLASSNAME, "@onTurretThink");
}

public @onTurretThink(ent)
{
  
    new target = getTargetByShotMode(ent, 500, TURRET_SHOT_MODE.Nearest);


    // if no monster in range
    if (target == -1)
    {
       // TODO: idle
    }
    else
    {

  i
       // TODO: Shot!
    }
}

@sendTurretShotForward(turrentEntity, id, targetId, turretKey[33])
{

}

@sendTurretLowAmmoForward(turretEntity, id, turretKey[33])
{
    new pluginId = getPluginIdByTurretKey(turretKey);

    executeOnTurretCreatedForward(pluginId, turretEntity, id);
}

@shotMonster(turret, monster)
{

}

@decreaseTurretAmmo(turret)
{
      new turretAmmo; CED_GettCell(ent, CED_TURRET_AMMO, turretAmmo);
      turretAmmo--;

      CED_SetCell(ent, CED_TURRET_AMMO, turretAmmo);
  
}