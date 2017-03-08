#include <amxmodx>
#include <td>

new iItem;
public plugin_init(){
	new id = register_plugin("TD: SHOP| Frozen Nade", "1.0", "GT Team")
	
	iItem = td_shop_register_item("Frozen grenade", "You get frozen grenade which slowing monster", 30, 0, id)
}

public td_shop_item_selected(id, itemid)
{
	if(iItem == itemid)
	{
		if(td_give_user_frozen_grenade(id) == 0)
		{
			client_print(id, print_center, "You have reached limit of frozen grenades");

			return PLUGIN_HANDLED;
		}
	}

	return PLUGIN_CONTINUE;
}
