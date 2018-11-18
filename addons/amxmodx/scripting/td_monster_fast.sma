#include <amxmodx>
#include <td>

#define PLUGIN "Tower Defense Monster: Fast"
#define VERSION "1.0"
#define AUTHOR "GT Team"

#define MONSTER_KEY "Fast"

#define MODEL_1 "models/Tower Defense/fast1.mdl"
#define MODEL_2 "models/Tower Defense/fast2.mdl"
#define MODEL_3 "models/Tower Defense/fast3.mdl"
#define MODEL_4 "models/Tower Defense/fast4.mdl"

public plugin_init() 
{
    register_plugin(PLUGIN, VERSION, AUTHOR);

    td_register_monster(MONSTER_KEY, MODEL_1, MODEL_2, MODEL_3, MODEL_4);
}

public plugin_precache()
{
    precache_model(MODEL_1);
    precache_model(MODEL_2);
    precache_model(MODEL_3);
    precache_model(MODEL_4);
}