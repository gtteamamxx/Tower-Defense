#if defined _towerdefense_turrets_natives_included
  #endinput
#endif
#define _towerdefense_turrets_natives_included

public plugin_natives()
{
    register_native("td_register_turret", "@_td_register_turret");
}

@_td_register_turret(pluginId, argc) 
{
    if(argc < 2) 
    {
        log_amx("Bad use of _td_register_monster by plugin %d. Arguments passed %d/2 needed", pluginId, argc);
        return false;
    }

    new turretKey[33];
    new turretName[33];

    get_string(1, turretKey, charsmax(turretKey));
    get_string(2, turretName, charsmax(turretName));

    registerTurret(pluginId, turretKey, turretName);

    return true;
}
 