#if defined _towerdefense_turrets_consts_included
  #endinput
#endif
#define _towerdefense_turrets_consts_included

#define TURRET_CLASSNAME "turret"
#define TURRET_MOVE_CLASSNAME "turret_move"

// player turret data keys
#define CED_PLAYER_TURRETS_ARRAY_KEY "player_turrets_array"
#define CED_PLAYER_MOVING_TURRET_ENTITY_KEY "turret_moving_ent"

// turret data keys
#define CED_TURRET_OWNER_KEY "turret_owner"
#define CED_TURRET_LEVEL "turret_level"
#define CED_TURRET_KEY "turret_key"

// moving turret data keys
#define CED_ENTITY_PLACE_POSIBILITY_KEY "turret_can_be_placed_here"
#define CED_TURRET_IS_MOVING "turret_is_moving"

#define TURRETS_SCHEMA "TURRETS"

#define MAX_COUNT_SCHEMA "MAX_COUNT"
#define DAMAGE_SCHEMA "DAMAGE"
#define RANGE_SCHEMA "RANGE"
#define FIRERATE_SCHEMA "FIRERATE"
#define ACCURACY_SCHEMA "ACCURACY"

#define DIST_MOVING 70.0

enum TURRET_INFO
{
    TURRET_MAX_COUNT,
    TURRET_DAMAGE,
    TURRET_RANGE,
    TURRET_FIRERATE,
    TURRET_ACCURACY
};

enum REGISTERED_TURRET_INFO
{
    TURRET_PLUGIN_ID,
    TURRET_KEY,
    TURRET_NAME,
}