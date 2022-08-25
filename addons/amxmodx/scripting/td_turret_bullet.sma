#include <amxmodx>
#include <td_turrets>

#define PLUGIN "Tower Defense Turret: Bullet"
#define VERSION "1.0"
#define AUTHOR "GT Team"

#define TURRET_KEY "BULLET"
#define TURRET_NAME "Bullet"

public plugin_init() 
{
    register_plugin(PLUGIN, VERSION, AUTHOR);

    td_register_turret(TURRET_KEY, TURRET_NAME);
}

public td_on_turret_created(ent, id)
{
    client_print(0, 3, "%d %d", ent, id);
}