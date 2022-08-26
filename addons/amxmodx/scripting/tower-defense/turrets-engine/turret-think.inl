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
    // get turret range
    new Float:shotRange = getTurretRangeToShot(ent);

    // get turret previous target
    new TURRET_PREVIOUSLY_TARGET:previousMonsterTarget = TURRET_PREVIOUSLY_TARGET:getTurretTargetMonster(ent);

    // get monster new target
    new TURRET_SHOT_RESULT:newMonsterTarget = getTargetByShotMode(ent, shotRange, FOLLOW);
    
    // if no monster in range
    if (newMonsterTarget == No_Monster_Found)
    {
        // if previous target was a monster then stop shotting
        if (previousMonsterTarget != No_Monster)
        {
            @onTurretStopFire(ent);
        }
        // idle
        else
        {
            @onTurretIdle(ent);
        }
    }
    // if monster is in range then shot
    else
    {
        // if we're shotting at same monster as previously
        if (_:previousMonsterTarget == _:newMonsterTarget)
        {
            @onTurretShot(ent, newMonsterTarget);
        }
        // if it's new monster then prepare to shot
        else
        {
            @onTurretStartShot(ent, _:newMonsterTarget);
        }
    }

    return PLUGIN_CONTINUE;
}

@onTurretStopFire(ent)
{
    // set current turret target
    @updateMonsterTarget(ent, _:No_Monster);

    // send forward
    @sendTurretStopFireForward(ent);

    // wait some time to find another monster
    entity_set_float(ent, EV_FL_nextthink, get_gametime() + 2.0);
}

@onTurretIdle(ent)
{
    // make turret animate
    @animateTurretIdle(ent);

    // check new monsters in range every 0.5 second
    entity_set_float(ent, EV_FL_nextthink, get_gametime() + 0.5);
}

@onTurretNoAmmo(ent)
{
    // send forward
    @sendTurretNoAmmoForward(ent);

    // stop turret
    entity_set_float(ent, EV_FL_nextthink, 0.0);
}

@onTurretShot(ent, any:monster)
{
    // shot
    @shot(ent, monster);

    // aim at monster with shot animate
    turnTurretToMonster(ent, monster, .turnBarrel = true);

    // decrease turret ammo
    @decreaseTurretAmmo(ent);

    // shot firerate
    entity_set_float(ent, EV_FL_nextthink, get_gametime() + 1.0);
}

@shot(ent, any:monster)
{
    @sendTurretShotForward(ent, monster);
}

@onTurretLowAmmo(ent)
{
    @sendTurretLowAmmoForward(ent)
}

@onTurretStartShot(ent, any:monster)
{
    // save new target
    @updateMonsterTarget(ent, monster);

    // aim at monster
    turnTurretToMonster(ent, monster);

    // send forward
    @sendTurretStartFireForward(ent, monster);

    // start shotting after 1s
    entity_set_float(ent, EV_FL_nextthink, get_gametime() + 1.0);
}

@decreaseTurretAmmo(ent)
{
    // get ammo and decrease
    new turretAmmo = getTurretAmmo(ent);
    turretAmmo--;

    // save data
    CED_SetCell(ent, CED_TURRET_AMMO, turretAmmo);

    // if ammo level reached low ammo send information
    if (turretAmmo < 10)
    {
        @onTurretLowAmmo(ent);
    }
    else if (turretAmmo == 0)
    {
        @onTurretNoAmmo(ent);
    }
}

@updateMonsterTarget(ent, any:monster)
{
    CED_SetCell(ent, CED_TURRET_TARGET_MONSTER_ENTITY, monster);
}

@animateTurretIdle(ent)
{
    // move to the right
    new controller1 = entity_get_byte(ent, EV_BYTE_controller1) + 2;
    if(controller1 > 255)
    {
        controller1 = 0;
    }

    entity_set_byte(ent, EV_BYTE_controller1, controller1);

    // center barrel
    entity_set_byte(ent, EV_BYTE_controller2, 127);
}

@sendTurretNoAmmoForward(ent)
{
    // get owner
    new ownerId = getTurretOwner(ent);

    // get turret key
    new turretKey[33];
    getTurretKey(ent, turretKey);

    // execute forward
    new pluginId = getPluginIdByTurretKey(turretKey);

    executeOnTurretNoAmmoForward(pluginId, ent, ownerId);
}

@sendTurretStartFireForward(ent, monster)
{
    // get owner
    new ownerId = getTurretOwner(ent);

    // get turret key
    new turretKey[33];
    getTurretKey(ent, turretKey);

    // execute forward
    new pluginId = getPluginIdByTurretKey(turretKey);

    executeOnTurretStartFireForward(pluginId, ent, monster, ownerId);
}

@sendTurretShotForward(ent, monster)
{
    // get owner
    new ownerId = getTurretOwner(ent);

    // get turret key
    new turretKey[33];
    getTurretKey(ent, turretKey);

    // execute forward
    new pluginId = getPluginIdByTurretKey(turretKey);

    executeOnTurretShotForward(pluginId, ent, monster, ownerId);
}

@sendTurretLowAmmoForward(ent)
{
    // get owner
    new ownerId = getTurretOwner(ent);

    // get turret key
    new turretKey[33];
    getTurretKey(ent, turretKey);

    // execute forward
    new pluginId = getPluginIdByTurretKey(turretKey);

    executeOnTurretLowAmmoForward(pluginId, ent, ownerId);
}

@sendTurretStopFireForward(ent)
{
    // get owner
    new ownerId = getTurretOwner(ent);

    // get turret key
    new turretKey[33];
    getTurretKey(ent, turretKey);

    // execute forward
    new pluginId = getPluginIdByTurretKey(turretKey);

    executeOnTurretStopFireForward(pluginId, ent, ownerId);
}