#include <amxmodx>
#include <td_turrets>
#include <engine>

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
    client_print(0, 3, "created", ent, id);
}

public td_on_turret_low_ammo(ent, id)
{
    client_print(0, 3, "low ammo", ent, id);
}

public td_on_turret_no_ammo(ent, id)
{
    client_print(0, 3, "no ammo", ent, id);
}

public td_on_turret_shot(ent, monster, id)
{
    client_print(0, 3, "shot %d %d %d", ent, monster, id);
}

public td_on_turret_start_fire(ent, monster, id)
{
    client_print(0, 3, "start fire %d %d %d", ent, monster, id);
}

public td_on_turret_stop_fire(ent, id)
{
    client_print(0, 3, "stop fire %d %d", ent, id);
}