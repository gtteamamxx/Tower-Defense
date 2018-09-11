#include <amxmodx>
#include <td>

#define PLUGIN "TD Shop: Minigun Ammo"
#define VERSION "1.0"
#define AUTHOR "gtteam"

native set_cp(id)
new gItem;
public plugin_init() {
	new id = register_plugin(PLUGIN, VERSION, AUTHOR)
	gItem = td_shop_register_item("Ammunition for Minigun", "Additional ammo for Minigun - 500", 100, 0, id)
}
public td_shop_item_selected(id, itemid)

	if(gItem == itemid)
		set_cp(id)

