#if defined td_engine_consts_includes
  #endinput
#endif
#define td_engine_consts_includes

#define MAP_START_ENTITY_NAME "start"
#define MAP_END_ENTITY_NAME "end"

#define CONFIG_DIRECTORY "addons/amxmodx/configs/Tower Defense"
#define DEFAULT_CONFIG_FILE "default_config_file.json"

#define MAP_CONFIG_KEY_LENGTH 64

enum MAP_ENTITIES_ENUM
{
  START_ENTITY,
  Float:START_ENTITY_ORIGIN[3],
  START_SPRITE_ENTITY,
  START_SPRITE_ORIGIN,
  END_ENTITY,
  Float:END_ENTITY_ORIGIN[3],
  TOWER_ENTITY,
  Float:TOWER_ENTITY_ORIGIN[3]
}

enum MAP_CONFIGURATION_ENUM
{
  bool:SHOW_START_SPRITE,
  bool:SHOW_TOWER,
  TOWER_HEALTH
}

enum MAP_CONFIGURATION_DATA_ENUM
{
  CONFIG_NAME[MAP_CONFIG_KEY_LENGTH],
  DataPack:DATAPACK
}

new const g_MapConfigurationKeys[MAP_CONFIGURATION_ENUM][MAP_CONFIG_KEY_LENGTH] = 
{
  "SHOW_START_SPRITE",
  "SHOW_TOWER",
  "TOWER_HEALTH"
}