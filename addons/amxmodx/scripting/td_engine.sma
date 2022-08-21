#include <amxmodx>
#include <engine>
#include <fakemeta_util>
#include <json>
#include <xs>
#include <cstrike>
#include <customentdata>
#include <hamsandwich>

#include "tower-defense/engine/consts.inl"
#include "tower-defense/engine/common.inl"
#include "tower-defense/engine/json-loader.inl"
#include "tower-defense/engine/json-wave-loader.inl"
#include "tower-defense/engine/startup.inl"
#include "tower-defense/engine/wave-manager.inl"
#include "tower-defense/engine/counter.inl"
#include "tower-defense/engine/monsters-manager.inl"
#include "tower-defense/engine/monster-types-manager.inl"
#include "tower-defense/engine/events.inl"
#include "tower-defense/engine/precaches.inl"
#include "tower-defense/engine/natives.inl"
#include "tower-defense/engine/add-to-full-pack.inl"
#include "tower-defense/engine/player.inl"
#include "tower-defense/engine/player-kills.inl"
#include "tower-defense/engine/tower.inl"

#pragma semicolon 1
#pragma dynamic 32768

#define PLUGIN "Tower Defense"
#define AUTHOR "GT Team"
#define VERSION "2.0"

public plugin_init()
{
    register_plugin(PLUGIN, VERSION, AUTHOR);

    registerClientCommands();
    registerMonsterEvents();

    registerAddToFullPack();

    @initTowerDefenseMod();
}

public plugin_end()
{
    @clearTowerDefenseMod();
}

@initTowerDefenseMod()
{
    loadMapConfiguration();
    checkGamePossibility();

    if(@isGamePossible())
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
    releaseArrays();
    relaseTries();
}

@isGamePossible()
{
    return getGameStatus();
}