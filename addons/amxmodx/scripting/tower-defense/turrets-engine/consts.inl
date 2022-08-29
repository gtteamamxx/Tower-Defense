#if defined _towerdefense_turrets_consts_included
  #endinput
#endif
#define _towerdefense_turrets_consts_included

#define TURRET_CLASSNAME "turret"
#define TURRET_MOVE_CLASSNAME "turret_move"

#define RANGER_CLASSNAME "ranger"

// player turret data keys
#define CED_PLAYER_TURRETS_ARRAY_KEY "player_turrets_array"
#define CED_PLAYER_MOVING_TURRET_ENTITY_KEY "player_turret_moving_ent"
#define CED_PLAYER_TOUCHING_TURRET_ENTITY_KEY  "player_turret_touching_ent"
#define CED_PLAYER_SHOWED_MENU_TURRET_KEY "player_showed_menu_turret_key"

// ranger data keys
#define CED_RANGER_TURRET_ENTITY_KEY "ranger_turret"
#define CED_RANGER_OWNER_KEY "ranger_owner"

// turret data keys
#define CED_TURRET_OWNER_KEY "turret_owner"
#define CED_TURRET_KEY "turret_key"
#define CED_TURRET_AMMO "turret_ammo"
#define CED_TURRET_IS_LOW_AMMO "turret_is_low_ammo"
#define CED_TURRET_ACCURACY_LEVEL "turret_accuracy"
#define CED_TURRET_FIRERATE_LEVEL "turret_firerate"
#define CED_TURRET_DAMAGE_LEVEL "turret_damage"
#define CED_TURRET_RANGE_LEVEL "turret_range"
#define CED_TURRET_TARGET_MONSTER_ENTITY "turret_target"
#define CED_TURRET_SHOT_MODE "turret_shot_mode"
#define CED_TURRET_IS_ENABLED "turret_enabled"
#define CED_TURRET_IS_UPGRADING "turret_is_upgrading"
#define CED_TURRET_IS_RELOADING "turret_is_reloading"

#define CED_TURRET_RANGER_MIN_ENTITY_KEY "turret_ranger_min"
#define CED_TURRET_RANGER_MAX_ENTITY_KEY "turret_ranger_max"

// moving turret data keys
#define CED_ENTITY_PLACE_POSIBILITY_KEY "turret_can_be_placed_here"
#define CED_TURRET_IS_MOVING "turret_is_moving"

#define TURRETS_SCHEMA "TURRETS"

#define MAX_COUNT_SCHEMA "MAX_COUNT"
#define DAMAGE_SCHEMA "DAMAGE"
#define RANGE_SCHEMA "RANGE"
#define FIRERATE_SCHEMA "FIRERATE"
#define ACCURACY_SCHEMA "ACCURACY"
#define ACTIVATION_TIME_SCHEMA "ACTIVATION_TIME"
#define RELOAD_TIME_SCHEMA "RELOAD_TIME"
#define UPGRADE_TIME_SCHEMA "UPGRADE_TIME"
#define START_AMMO_SCHEMA "START_AMMO"
#define RELOAD_AMMO_SCHEMA "RELOAD_AMMO"

#define DIST_MOVING 70.0

enum TURRET_INFO
{
    TURRET_MAX_COUNT,
    TURRET_ACTIVATION_TIME,
    TURRET_RELOAD_TIME,
    TURRET_UPGRADE_TIME,
    TURRET_START_AMMO,
    TURRET_RELOAD_AMMO,
    TURRET_DAMAGE,
    TURRET_RANGE,
    TURRET_FIRERATE,
    TURRET_ACCURACY
};

enum TURRET_SHOT_RESULT
{
    No_Monster_Found = -1
}

enum TURRET_PREVIOUSLY_TARGET
{
    No_Monster
}

enum TURRET_SHOT_MODE
{
    NEAREST,
    FARTHEST,
    STRONGEST,
    WEAKEST,
    FOLLOW
}

enum REGISTERED_TURRET_INFO
{
    TURRET_PLUGIN_ID,
    TURRET_KEY,
    TURRET_NAME,
}