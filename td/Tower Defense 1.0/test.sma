#include <amxmodx>
#include <iostream>
#include <fun>
#include <cstrike>

public plugin_init()
{
    register_plugin("TEST", "WDA", "HOPA");

    register_clcmd("say /test", "test");
}

public test(id)
{
    if(!is_user_connected(id))
        return;

    set_user_health(id, get_user_health(id) + 50);
    cs_set_user_armor(id, 100);
    return;
}

