/* Plugin generated by AMXX-Studio */

#include <amxmodx>
#include <amxmisc>
#include <td>
#include <engine>
#include <colorchat>
#include <cstrike>

#define PLUGIN "TD Assits: v2"
#define VERSION "1.0"
#define AUTHOR "grs4"

#define MAX_MONSTERS 50

enum ENUM_CVARS
{
	CVAR_ENABLED,
	CVAR_ASSIST_GOLD,
	CVAR_ASSIST_MONEY,
	CVAR_ASSIST_GOLD_SPECIAL,
	CVAR_ASSIST_MONEY_SPECIAL,
	CVAR_DAMAGE_PERCENT,
	CVAR_ASSIST_GUNMOD_EXP
}
new g_CvarPointers[ENUM_CVARS];
new g_CvarValues[ENUM_CVARS];
new Float:g_CvarDamagePercentValue

new bool:isGunmodEnabled = false;

new Trie:g_tMonsters
new Array:g_aMonsters;

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	g_CvarPointers[CVAR_ENABLED] 			= 	register_cvar("td_assists_on", "1")
	
	g_CvarPointers[CVAR_ASSIST_GOLD]		= 	register_cvar("td_assists_gold", "1") // Normal, fast, strenght
	g_CvarPointers[CVAR_ASSIST_MONEY] 		= 	register_cvar("td_assists_money", "75")
	g_CvarPointers[CVAR_ASSIST_GOLD_SPECIAL] 	= 	register_cvar("td_assists_gold_special", "5") // Boss/bonus
	g_CvarPointers[CVAR_ASSIST_MONEY_SPECIAL] 	= 	register_cvar("td_assists_money_special", "200") // Boss/bonus
	
	g_CvarPointers[CVAR_DAMAGE_PERCENT] 		= 	register_cvar("td_assists_min_damage_percent", "0.4")
	g_CvarPointers[CVAR_ASSIST_GUNMOD_EXP]    	= 	register_cvar("td_assists_gunmod_exp", "1");

	td_settings_refreshed();
	set_task(3.0, "CheckIfGunModExist");
	
	g_tMonsters = TrieCreate();
	g_aMonsters = ArrayCreate(1, MAX_MONSTERS);
	
}

public td_settings_refreshed()
{
	g_CvarValues[CVAR_ENABLED]			=	get_pcvar_num(g_CvarPointers[CVAR_ENABLED]);
	g_CvarValues[CVAR_ASSIST_GOLD]			=	get_pcvar_num(g_CvarPointers[CVAR_ASSIST_GOLD]);
	g_CvarValues[CVAR_ASSIST_MONEY]			=	get_pcvar_num(g_CvarPointers[CVAR_ASSIST_MONEY]);
	g_CvarValues[CVAR_ASSIST_GOLD_SPECIAL]		=	get_pcvar_num(g_CvarPointers[CVAR_ASSIST_GOLD_SPECIAL]);
	g_CvarValues[CVAR_ASSIST_MONEY_SPECIAL]		=	get_pcvar_num(g_CvarPointers[CVAR_ASSIST_MONEY_SPECIAL]);
	g_CvarDamagePercentValue			=	get_pcvar_float(g_CvarPointers[CVAR_DAMAGE_PERCENT]);
	g_CvarValues[CVAR_ASSIST_GUNMOD_EXP] 		= 	get_pcvar_num(g_CvarPointers[CVAR_ASSIST_GUNMOD_EXP]);
}
public CheckIfGunModExist()
{
	if(is_plugin_loaded("td_gunmod.amxx", true) != -1)
		isGunmodEnabled = true;
}	

public plugin_end()
{
	ResetMemory()
	ArrayDestroy(g_aMonsters);
	TrieDestroy(g_tMonsters);
}

public ResetMemory()
{
	new size = ArraySize(g_aMonsters), ent[4], arrayId;
	
	for(new i = 0; i < size; i++)
	{
		num_to_str(ArrayGetCell(g_aMonsters, i), ent, charsmax(ent))
		
		TrieGetCell(g_tMonsters, ent, arrayId);
		
		ArrayDestroy(Array:arrayId);
	}
}
public td_monster_killed(iEnt, iPlayer, iMonsterType, IsKilledByWeapon)
{
	if(!checkMonsterIsInDatabase(iEnt))
		return;
		
	new players[33], len;
	getPlayersWhichGotAssist(iEnt, players, len);

	for(new i = 0; i < len; i++)
	{
		static player;
		player = players[i];
		
		if(!is_user_connected(player) || player == iPlayer)
			continue;
		
		addPlayerBenefitsForAssist(player, iEnt);
	}
	
	removeMonsterFromMemory(iEnt)
}

public td_take_damage_post(iPlayer, iEnt, iWeapon, Float:fOutDamage, szInDamage[3])
{
	static ent[4];
	num_to_str(iEnt, ent, charsmax(ent));
	if(!addMonserToDatabaseIfNotExist(ent, iPlayer, floatround(fOutDamage)))
	{
		new arrayId = getDatabaseIdFromMonster(ent), arraypos;
		new playerId = getPlayerArrayIndexInDatabase(Array:arrayId, iPlayer, arraypos);

		if(playerId)
			updatePlayerData(Array:arrayId, arraypos, floatround(fOutDamage));
		else
			addPlayerArrayToDatabase(Array:arrayId, iPlayer, floatround(fOutDamage));
	}
}

public addPlayerBenefitsForAssist(id, iEnt)
{
	new iMonsterType = td_get_monster_type(iEnt);
	new bool:IsSpecialMonster = iMonsterType == ROUND_BONUS || iMonsterType == ROUND_BOSS
	
	new iGold; iGold = IsSpecialMonster ? g_CvarValues[CVAR_ASSIST_GOLD_SPECIAL] : g_CvarValues[CVAR_ASSIST_GOLD]
	new iMoney; iMoney = IsSpecialMonster ? g_CvarValues[CVAR_ASSIST_MONEY_SPECIAL] : g_CvarValues[CVAR_ASSIST_MONEY]
	
	if(isGunmodEnabled)
	{
		static value;
		if(!value)
			value = g_CvarValues[CVAR_ASSIST_GUNMOD_EXP];

		if(value)
		{
			callfunc_begin("_addUserExp", "td_gunmod.amxx");
			callfunc_push_int(id);
			callfunc_push_int(value);
			callfunc_end();
		}
	}
		
	td_set_user_info(id, PLAYER_GOLD, td_get_user_info(id, PLAYER_GOLD) + iGold)
	
	static userMoney; userMoney = cs_get_user_money(id)
	cs_set_user_money(id, ( userMoney + iMoney ) > 16000 ? 16000 : ( userMoney + iMoney), 1)
	
	ColorChat(id, GREEN, "[TD]^x01 You got %d gold and $%d for assist with killing a moster!",  iGold, iMoney)
}

public removeMonsterFromMemory(iEnt)
{
	new ent[4], size
	num_to_str(iEnt, ent, charsmax(ent));
	
	new arrayId = getDatabaseIdFromMonster(ent);
	ArrayDestroy(Array:arrayId);
	TrieDeleteKey(g_tMonsters, ent);
	
	size = ArraySize(g_aMonsters);
	for(new i; i < size; i++)
	{
		if(ArrayGetCell(g_aMonsters, i) == iEnt)
		{
			ArrayDeleteItem(g_aMonsters, i);
			break;
		}
	}
		
}
stock getPlayersWhichGotAssist(iEnt, players[33], &len)
{
	new ent[4]
	num_to_str(iEnt, ent, charsmax(ent));
	
	new Array:array = Array:getDatabaseIdFromMonster(ent);
	new size = ArraySize(array), tab[2], monsterHealth = td_get_monster_maxhealth(iEnt), id;
	
	for(new i = 0; i < size; i++)
	{
		ArrayGetArray(array, i, tab);
		id = checkArrayAndGetPlayerIdIfGotAssist(tab, monsterHealth);
		if(id)
			players[len++] = id;
	}
}

stock checkArrayAndGetPlayerIdIfGotAssist(tab[2], health)
{
	new damage = tab[1];
	
	if((damage / float(health)) >= g_CvarDamagePercentValue)
		return tab[0]
	return 0;
}
stock bool:checkMonsterIsInDatabase(iEnt)
{
	new ent[4]
	num_to_str(iEnt, ent, charsmax(ent));
	return TrieKeyExists(g_tMonsters, ent)
}
stock updatePlayerData(Array:array, arraypos, damage)
{
	new tab[2]
	ArrayGetArray(array, arraypos, tab);
	tab[1] += damage;
	ArraySetArray(array, arraypos, tab);
}

stock addPlayerArrayToDatabase(Array:array, id, damage)
{
	new tab[2];
	tab[0] = id;
	tab[1] = damage;
	ArrayPushArray(array, tab)
}

stock getPlayerArrayIndexInDatabase(Array:array, id, &arraypos)
{
	new size = ArraySize(array), tab[2];
	
	for(new i = 0 ; i < size; i++)
	{
		ArrayGetArray(array, i, tab);
		
		if(tab[0] == id)
		{
			arraypos = i;
			return id;
		}
	}
	
	return 0;
}
stock getDatabaseIdFromMonster(Ent[])
{
	new arrayId;
	TrieGetCell(g_tMonsters, Ent,arrayId);
	return arrayId
}
stock addMonserToDatabaseIfNotExist(Ent[], iPlayer, damage)
{
	if(!TrieKeyExists(g_tMonsters, Ent))
	{
		new Array:array = ArrayCreate(2, 32), tab[2];
		tab[0] = iPlayer;
		tab[1] = damage;
		ArrayPushArray(array, tab);
		TrieSetCell(g_tMonsters, Ent, _:array)
		
		ArrayPushCell(g_aMonsters, str_to_num(Ent));
		return 1;
	}
	return 0;
}
	
	
