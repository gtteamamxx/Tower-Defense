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
}