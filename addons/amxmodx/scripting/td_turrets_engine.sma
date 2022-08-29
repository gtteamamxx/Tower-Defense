#include <amxmodx>
#include <json>
#include <customentdata>
#include <td>
#include <cstrike>
#include <engine>
#include <fakemeta_util>
#include <customentdata>
#include <hamsandwich>

#include "tower-defense/engine/consts.inl"

#include "tower-defense/turrets-engine/consts.inl"
#include "tower-defense/turrets-engine/global.inl"
#include "tower-defense/turrets-engine/precache.inl"
#include "tower-defense/turrets-engine/common.inl"
#include "tower-defense/turrets-engine/json-configuration-loader.inl"
#include "tower-defense/turrets-engine/cleaner.inl"
#include "tower-defense/turrets-engine/td-events.inl"
#include "tower-defense/turrets-engine/player-commands.inl"
#include "tower-defense/turrets-engine/natives.inl"
#include "tower-defense/turrets-engine/forwards.inl"
#include "tower-defense/turrets-engine/calculate-monster-target.inl"
#include "tower-defense/turrets-engine/turret-registration.inl"
#include "tower-defense/turrets-engine/turrets-menu.inl"
#include "tower-defense/turrets-engine/turret-detail-menu.inl"
#include "tower-defense/turrets-engine/player-turret-create-menu.inl"
#include "tower-defense/turrets-engine/turret-events.inl"
#include "tower-defense/turrets-engine/turret-move-manager.inl"
#include "tower-defense/turrets-engine/turret-creation.inl"
#include "tower-defense/turrets-engine/player-events.inl"
#include "tower-defense/turrets-engine/player-turret-touch-information.inl"
#include "tower-defense/turrets-engine/turret-think.inl"
#include "tower-defense/turrets-engine/ranger-events.inl"
#include "tower-defense/turrets-engine/ranger-manager.inl"

#pragma semicolon 1
#pragma dynamic 32768

#define PLUGIN "Tower Defense: Turrets Engine"
#define AUTHOR "GT Team"
#define VERSION "2.0"

public plugin_init()
{
    register_plugin(PLUGIN, VERSION, AUTHOR);

    registerPlayerCommands();
    registerPlayerEvents();    

    registerTurretEvents();
    registerRangerEvents();

    set_task(1.0, "@checkIfTurretsAreAvailable");
}

public plugin_end()
{
    // on plugin end free all resources
    freeResourcesOnPluginEnd();
}

@checkIfTurretsAreAvailable()
{
    // if no turrets registered do nothing
    if (getNumberOfRegisteredTurrets() == 0)
    {
        log_amx("[TURRETS] No turrets loaded.");
    }
    
    // if there are registered turrets then let
    // module start
    //
    // turret registration is madde only when config is loaded
    // so valdiating number of registration turrets shows
    // if we have also valid configuration 
    else
    {
        g_AreTurretsAvailable = true;
    }
}