#include <amxmodx>
#include <iostream>
#include <fun>

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
}

