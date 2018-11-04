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
    @initTries();

    loadMapConfiguration();
    checkMapConfiguration();
    
    if(@isGamePossible())
    {
       initializeGame(); 
    }
    else 
    {
        log_amx("Game is not possible");
    }
}

@initTries()
{
    @initMapConfigurationTrie();
}

@initMapConfigurationTrie()
{
    g_MapConfigurationKeysTrie = TrieCreate();

    TrieSetCell(g_MapConfigurationKeysTrie, "SHOW_START_SPRITE", _:SHOW_START_SPRITE);
    TrieSetCell(g_MapConfigurationKeysTrie, "SHOW_END_SPRITE", _:SHOW_END_SPRITE);
    TrieSetCell(g_MapConfigurationKeysTrie, "SHOW_TOWER", _:SHOW_BLAST_ON_MONSTER_TOWER_TOUCH);
    TrieSetCell(g_MapConfigurationKeysTrie, "TOWER_HEALTH", _:TOWER_HEALTH);
    TrieSetCell(g_MapConfigurationKeysTrie, "SHOW_BLAST_ON_MONSTER_TOWER_TOUCH", _:SHOW_BLAST_ON_MONSTER_TOWER_TOUCH);
}

@clearTowerDefenseMod()
{
}

@isGamePossible()
{
    return getGameStatus();
}