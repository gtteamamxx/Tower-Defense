#if defined td_engine_consts_includes
  #endinput
#endif
#define td_engine_consts_includes

#define MAP_START_ENTITY_NAME "start"
#define MAP_END_ENTITY_NAME "end"

#define START_SPRITE_ENTITY_NAME "start_sprite"
#define END_SPRITE_ENTITY_NAME "end_sprite"

#define TOWER_ENTITY_NAME "tower"

#define CONFIG_DIRECTORY "addons/amxmodx/configs/Tower Defense"
#define DEFAULT_CONFIG_FILE "default_config_file.json"

#define MAP_CONFIG_KEY_LENGTH 64

enum MAP_ENTITIES_ENUM
{
  START_ENTITY,
  START_SPRITE_ENTITY,
  END_ENTITY,
  END_SPRITE_ENTITY,
  TOWER_ENTITY,
}

enum MAP_CONFIGURATION_ENUM
{
  bool:SHOW_START_SPRITE,
  bool:SHOW_END_SPRITE,
  bool:SHOW_TOWER,
  bool:SHOW_BLAST_ON_MONSTER_TOWER_TOUCH,
  TOWER_HEALTH
}

enum MODELS_ENUM
{
  TOWER_MODEL,
  START_SPRITE_MODEL,
  END_SPRITE_MODEL
}

