#include <amxmodx>
#include <engine>
#include <json>
#include <xs>

#include "tower-defense/engine/consts.inl"
#include "tower-defense/engine/common.inl"
#include "tower-defense/engine/precaches.inl"
#include "tower-defense/engine/json-loader.inl"
#include "tower-defense/engine/startup.inl"

#pragma semicolon 1
#pragma dynamic 32768

#define PLUGIN "Tower Defense"
#define AUTHOR "GT Team"
#define VERSION "2.0"

public plugin_init()
{
    register_plugin(PLUGIN, VERSION, AUTHOR);

    @initTowerDefenseMod();
}

public plugin_end()
{
    @clearTowerDefenseMod();
}

@initTowerDefenseMod()
{
    initCommon();

    loadMapConfiguration();
    checkMapConfiguration();

    if(@checkIfGameIsPossible())
    {
       initializeGame(); 
    }
    else 
    {
        log_amx("Game is not possible");
    }
}

@clearTowerDefenseMod()
{
    freeCommon();
}

@checkIfGameIsPossible()
{
    return getGameStatus();
}