#include <amxmodx>

#define PLUGIN  "Spectator Banner Ads"
#define VERSION "0.1.16"
#define AUTHOR  "iG_os"

#define SVC_DIRECTOR 51  // come from util.h
#define DRC_CMD_BANNER 9 // come from hltv.h

// sum of tga files
#define TGASUM 1

// tga of banners
new szTga[TGASUM][] ={
	"gfx/tower_defense.tga",
}

new g_SendOnce[33]

public plugin_precache()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	register_logevent("joined_team", 3, "1=joined team")
	
	for (new i=0; i<TGASUM; i++)
		precache_generic(szTga[i])
}


public client_putinserver(id)
{
	g_SendOnce[id] = true
}

public joined_team()
{
	new loguser[80], name[32]
	read_logargv(0, loguser, 79)
	parse_loguser(loguser, name, 31)
	new id = get_user_index(name)
	
	if (g_SendOnce[id] && is_user_connected(id) )
	{
		// random select one tga
		new index = random_num( 0, TGASUM - 1)
		g_SendOnce[id] = false
		
		// send show tga command to client
		message_begin( MSG_ONE, SVC_DIRECTOR, _, id )
		write_byte( strlen( szTga[index]) + 2 ) // command length in bytes
		write_byte( DRC_CMD_BANNER )
		write_string( szTga[index] ) // banner file
		message_end()
	}
}


/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1045\\ f0\\ fs16 \n\\ par }
*/
