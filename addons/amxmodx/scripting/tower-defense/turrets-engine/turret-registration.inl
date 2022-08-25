#if defined _towerdefense_turrets_registration_included
  #endinput
#endif
#define _towerdefense_turrets_registration_included

public registerTurret(pluginId, turretKey[33], turretName[33])
{
    // if there's no config for turrets we don't have to init turret for no reason
    // also if there's no configuration or allowed number of turrets is equal zero
    // we don't have to init turret
    if (getNumberOfLoadedTurrets() == 0)
    {
        log_amx("[TURRETS] Cannot register turret %s. No config for all turrets", turretKey);
        return;
    }

    if(!isConfigurationExistForTurret(turretKey))
    {
        log_amx("[TURRETS] Cannot register turret %s. Configuration for this turret is not present", turretKey);
        return;
    }
    
    if(getMaxNumberOfTurrets(turretKey) == 0)
    {
        log_amx("[TURRETS] Turret %s will not be registered. %S for turret is 0", turretKey, MAX_COUNT_SCHEMA);
        return;
    }

    // create array for turret
    new Array:turretInfoArray = ArrayCreate(.cellsize = 33);
    
    // save informations in REGISTERED_TURRET_INFO order
    ArrayPushCell(turretInfoArray, pluginId);
    ArrayPushString(turretInfoArray, turretKey);
    ArrayPushString(turretInfoArray, turretName);

    // save registered turret info
    TrieSetCell(g_RegisteredTurretsTrie, turretKey, turretInfoArray);

    log_amx("[TURRETS] Turret %s regsitered", turretKey);
}