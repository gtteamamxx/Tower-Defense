#include <amxmodx>
#include <td>

new iItem;

public plugin_init(){
	new id = register_plugin("TD: SHOP| Stop Nade", "1.0", "GT Team")
	iItem = td_shop_register_item("Stopping grenade", "Stopping grenade - freezing monsters for 5 seconds", 75, 0, id)
}

public td_shop_item_selected(id, itemid)
{
	if(iItem == itemid)
	{
		if(td_give_user_stop_grenade(id) == 0)
		{
			client_print(id, print_center, "You have reached limit of stop grenades");

			return PLUGIN_HANDLED;
		}
	}

	return PLUGIN_CONTINUE;
}
