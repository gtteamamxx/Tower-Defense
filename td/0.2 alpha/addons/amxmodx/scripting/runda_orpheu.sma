#include <amxmodx>
#include <amxmisc>

#include <orpheu>
#include <orpheu_memory>
#include <orpheu_advanced>

#define PLUGIN "Usuwanie konca rundy"
#define VERSION "1.0"
#define AUTHOR "arkshine (edit by cypis)"

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	OrpheuRegisterHook(OrpheuGetFunction("CheckMapConditions", "CHalfLifeMultiplay"), "game_blockConditions");
	OrpheuRegisterHook(OrpheuGetFunction("CheckWinConditions", "CHalfLifeMultiplay"), "game_blockConditions");

	if(is_linux_server())
		OrpheuRegisterHook(OrpheuGetFunction("HasRoundTimeExpired", "CHalfLifeMultiplay"), "game_blockConditions");
	else
		game_memoryReplace("roundTimeCheck", {0x90, 0x90, 0x90});
}

public OrpheuHookReturn:game_blockConditions()
{
	OrpheuSetReturn(false);
	return OrpheuSupercede;
}

game_memoryReplace(szID[], const iBytes[], const iLen = sizeof iBytes)
{
	new iAddress;
	OrpheuMemoryGet(szID, iAddress);

	for(new i; i < iLen; i++)
	{
		OrpheuMemorySetAtAddress(iAddress, "roundTimeCheck|dummy", 1, iBytes[i], iAddress);
		iAddress++;
	}
	server_cmd("sv_restart 1");
}
