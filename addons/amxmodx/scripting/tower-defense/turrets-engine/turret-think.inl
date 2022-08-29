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
    // if turret cannot be active, we don't want to let it
    if (!@canBeTurretActivated(ent)) 
    {
        // check can be turret activated after a while
        entity_set_float(ent, EV_FL_nextthink, get_gametime() + 0.5);
        return PLUGIN_CONTINUE;
    }

    // get turret range
    new Float:shotRange = getTurretRangeToShot(ent);

    // get turret previous target
    new TURRET_PREVIOUSLY_TARGET:previousMonsterTarget = TURRET_PREVIOUSLY_TARGET:getTurretTargetMonster(ent);

    // get monster new target
    new TURRET_SHOT_MODE:turretShotMode = getTurretShotMode(ent);
    new TURRET_SHOT_RESULT:newMonsterTarget = getTargetByShotMode(ent, shotRange, turretShotMode);
    
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

    emit_sound(ent, CHAN_AUTO, "TDNew/turret_stop.wav", 1.0, ATTN_NORM, 0, PITCH_NORM);

    // wait some time to find another monster
    entity_set_float(ent, EV_FL_nextthink, get_gametime() + 2.0);

    @showTurretHudInformationIfIsPlayerInDetailMenu(ent, "TARGET GONE");
}

@onTurretIdle(ent)
{
    // make turret animate
    @animateTurretIdle(ent);

    // check new monsters in range every 0.5 second
    entity_set_float(ent, EV_FL_nextthink, get_gametime() + 0.5);

    @showTurretHudInformationIfIsPlayerInDetailMenu(ent, "SEARCHING");
}

@onTurretNoAmmo(ent)
{
    // send forward
    @sendTurretNoAmmoForward(ent);

    new ownerId = getTurretOwner(ent);

    // emit sound on turret location
    emit_sound(ent, CHAN_AUTO, "TDNew/turret_noammo.wav", 1.0, ATTN_NORM, 0, PITCH_NORM);

    // emit sound for player
    client_cmd(ownerId, "spk TDNew/turret_noammo.wav");

    // stop turret
    entity_set_float(ent, EV_FL_nextthink,  0.0);
}

@onTurretShot(ent, any:monster)
{
    // shot
    @shot(ent, monster);

    // aim at monster with shot animate
    turnTurretToMonster(ent, monster, .turnBarrel = true);

    // decrease turret ammo
    @decreaseTurretAmmo(ent);

    // if no ammo, we can't calculate next think
    // because turret need to be stopped
    new turretAmmo = getTurretAmmo(ent);
    if (turretAmmo > 0)
    {
        // shot by turret firerate
        new Float:firerate = @getTurretFirerate(ent);

        entity_set_float(ent, EV_FL_nextthink, get_gametime() + firerate);
    }
}

@shot(ent, any:monster)
{
    new Float:turretAccuracy[2];
    getCurrentTurretAccuracy(ent, turretAccuracy);

    new Float:accuracy = random_float(turretAccuracy[0], turretAccuracy[1]);
    new bool:isShotMiss = bool:(random_float(0.0, 1.0) <= (1.0 - accuracy));

    if (isShotMiss)
    {
        @sendTurretShotMissForward(ent, monster);
        @showTurretHudInformationIfIsPlayerInDetailMenu(ent, "MISS");
    } 
    else
    {
        new Float:distance = entity_range(ent, monster);
        new Float:damage = getTurretDamageForDistance(ent, distance);

        @sendTurretShotForward(ent, monster, damage);

        new szDamage[128];
        num_to_str(floatround(damage), szDamage, 127);
        @showTurretHudInformationIfIsPlayerInDetailMenu(ent, szDamage);
    }
}

@onTurretLowAmmo(ent)
{
    @sendTurretLowAmmoForward(ent)

    new ownerId = getTurretOwner(ent);    

    emit_sound(ent, CHAN_AUTO, "TDNew/turret_lowammo.wav", 1.0, ATTN_NORM, 0, PITCH_NORM);

    client_cmd(ownerId, "spk TDNew/turret_lowammo.wav");

    @showTurretHudInformationIfIsPlayerInDetailMenu(ent, "LOW AMMO!");
}

@onTurretStartShot(ent, any:monster)
{
    // save new target
    @updateMonsterTarget(ent, monster);

    // aim at monster
    turnTurretToMonster(ent, monster);

    // send forward
    @sendTurretStartFireForward(ent, monster);

    emit_sound(ent, CHAN_AUTO, "TDNew/turret_start.wav", 1.0, ATTN_NORM, 0, PITCH_NORM);

    // start shotting after 1s
    entity_set_float(ent, EV_FL_nextthink, get_gametime() + 1.0);

    @showTurretHudInformationIfIsPlayerInDetailMenu(ent, "TARGET FOUND");
}

@decreaseTurretAmmo(ent)
{
    // get ammo and decrease
    new turretAmmo = getTurretAmmo(ent);
    turretAmmo--;

    // save data
    CED_SetCell(ent, CED_TURRET_AMMO, turretAmmo);

    // if low ammo level reached, send notification
    if (getTurretLowAmmoLevel(ent) == turretAmmo)
    {
        @onTurretLowAmmo(ent);
    }
    else if (turretAmmo == 0)
    {
        @onTurretNoAmmo(ent);
    }

    // refresh turret detail menu if is opened
    // to update for e.g. ammo count
    refreshTurretDetailMenuIfPlayerStillHaveItOpened(ent);
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

@sendTurretShotMissForward(ent, monster)
{
    // get owner
    new ownerId = getTurretOwner(ent);

    // get turret key
    new turretKey[33];
    getTurretKey(ent, turretKey);

    // execute forward
    new pluginId = getPluginIdByTurretKey(turretKey);

    executeOnTurretShotMissForward(pluginId, ent, monster, ownerId);
}

@sendTurretShotForward(ent, monster, Float:damage)
{
    // get owner
    new ownerId = getTurretOwner(ent);

    // get turret key
    new turretKey[33];
    getTurretKey(ent, turretKey);

    // execute forward
    new pluginId = getPluginIdByTurretKey(turretKey);

    executeOnTurretShotForward(pluginId, ent, monster, ownerId, damage);
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

Float:@getTurretFirerate(ent)
{
    new Float:firerateLevels[2];
    getCurrentTurretFirerate(ent, firerateLevels);

    new Float:firerate = random_float(firerateLevels[0], firerateLevels[1]);

    return firerate;
}

@showTurretHudInformationIfIsPlayerInDetailMenu(ent, szMessage[128])
{
    new ownerId = getTurretOwner(ent);
    if (getShowedTurretEntInDetailMenu(ownerId) == ent)
    {
        set_dhudmessage(255, 255, 255, -1.0, 0.9, 0, 0.9, 0.5);
        show_dhudmessage(ownerId, szMessage);
    }
}

bool:@canBeTurretActivated(ent)
{
    return isTurretEnabled(ent) && !isTurretReloading(ent);
}
