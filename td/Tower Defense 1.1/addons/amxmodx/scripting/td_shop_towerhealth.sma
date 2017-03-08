/* Plugin generated by AMXX-Studio */

#include <amxmodx>
#include <td>
//#include <td_const>
#include <colorchat>

#define PLUGIN "TD: Shop | Tower Health"
#define VERSION "1.0"
#define AUTHOR "tomcionek15 & grs4"

new iItem;

public plugin_init()  {
	new id = register_plugin(PLUGIN, VERSION, AUTHOR)
	
	iItem = td_shop_register_item("Health for Tower", "Rebuild Tower - increase Tower Health about 3. Rebuilding time - 7 seconds", 25, 0, id)
}
public td_shop_item_selected(id, itemid) 
{
	if(iItem == itemid) 
	{
		if(td_get_tower_health() + 3 > td_get_max_tower_health( )) 
		{
			ColorChat(id, GREEN, "[TD]^x01 You cannot buy this item. Tower health is MAX!")
			return PLUGIN_HANDLED
		}
		
		ColorChat(id, GREEN, "[TD]^x01 Rebulding tower...[^x04 7 seconds^x01 ]!")

		set_task(5.0, "TaskSetTowerHealth", id + 5541)
	}
	
	return PLUGIN_CONTINUE
}

public TaskSetTowerHealth(taskid) 
{
	new id = (taskid - 5541)
	
	/*if(td_get_end_status() == PLAYERS_LOSE) {
		ColorChat(id, GREEN, "[TD: SHOP]^x01 Ulepszanie wiezy nie powiodlo sie! Ludzie^x03 przegrali^x01 bitwe.")
		return PLUGIN_CONTINUE
	}
	*/
	
	if(td_get_tower_health() + 3 > td_get_max_tower_health( )) 
	{
		ColorChat(id, GREEN, "[TD]^x01 Rebuilding failed. Tower health is MAX!")
		ColorChat(id, GREEN, "[TD]^x01 You receive back 25 gold!")
		
		td_set_user_info(id, PLAYER_GOLD, td_get_user_info(id, PLAYER_GOLD) + 25);
		return
	}
		
	new szName[33];
	get_user_name(id, szName, 32)
	
	ColorChat(id, GREEN, "[TD]^x01 Rebuilding completed!")
	ColorChat(0, GREEN, "[TD]^x01 Player^x04 '%s'^x01 rebuilded tower with^x04 3 health units^x01 !", szName)
	
	td_set_tower_health(1, 3, 0)
}