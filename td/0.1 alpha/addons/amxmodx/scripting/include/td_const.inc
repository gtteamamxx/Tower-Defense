/* TFCX const
 *
 * (c) 2004, SidLuke
 * This file is provided as is (no warranties).
 */

#if defined _towerdefense_const_included
  #endinput
#endif
#define _towerdefense_const_included

enum eGame {
	GAME_NOT_AVAILABLE,
	GAME_AVAILABLE
}

enum e_RoundType{
	
	ROUND_NONE = 0,
	ROUND_NORMAL,
	ROUND_FAST,
	ROUND_STRENGHT,
	ROUND_BOSS,
	ROUND_BONUS
	
}

enum e_WaveInfo {
	e_RoundType:WAVE_ROUND_TYPE,
	WAVE_MONSTER_NUM,
	WAVE_MONSTER_HEALTH,
	WAVE_MONSTER_SPEED,
	WAVE_SPECIAL_HEALTH,
	WAVE_SPECIAL_SPEED
}

enum e_Player {
	PLAYER_GOLD,
	PLAYER_FRAGS,
	PLAYER_LEVEL,
	PLAYER_EXTRA_DAMAGE,
	PLAYER_EXTRA_SPEED,
	PLAYER_EXTRA_GOLD,
	PLAYER_EXTRA_MONEY
}

enum e_EndType {
	PLAYERS_WIN,
	PLAYERS_LOSE
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1045\\ f0\\ fs16 \n\\ par }
*/
