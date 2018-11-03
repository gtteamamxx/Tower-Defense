#if defined td_engine_consts_includes
  #endinput
#endif
#define td_engine_consts_includes

#define MAP_START_ENTITY_NAME "start"
#define MAP_END_ENTITY_NAME "end"

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

enum MAP_CONFIGURATION
{
  bool:SHOW_START_SPRITE,
  bool:SHOW_TOWER,
  TOWER_HEALTH
}