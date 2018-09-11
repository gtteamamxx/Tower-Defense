#if defined _towerdefense_included
  #endinput
#endif
#define _towerdefense_included

#if !defined towerdefense_const_included
	#include <td_const>
#endif

/* Zwraca maksymalna liczbe wavow */
native td_get_max_wave()

/* Zwraca maksymalna liczbe potworow na wave */
native td_get_max_monsters()

/* Zwraca maksymalny poziom gracza */
native td_get_max_level()

/* Zwraca '1' jesli to runda specjalna BOSS, BONUS*/
native td_is_special_wave(iWave)

/* Zwraca '1' jesli to BOSS, '2' jesli to BONUS*/
native td_is_special_monster(iEnt)

/* Zwraca '1' jesli to healthbar*/
native td_is_healthbar(iEnt)

/* Zwraca '1' jesli to potwor*/
native td_is_monster(iEnt)

/* Zwraca status gry */
native eGame:td_get_game_status()

/* Ustawia status gry */
native td_set_game_status(eGame:iStatus)

/* Zwraca aktualny wave */
native td_get_wave()

/* Ustawia aktualny wave */
native td_set_wave(iWave)

/* Zwraca liczbe wszystkich wavow */
native td_get_wavenum()

/* Zwraca informacje o rundzie */
native td_get_wave_info(iWave, e_WaveInfo:iInfo)

/* Ustawia informacje o rundzie 
	@UWAGA: Typ rundy ustawiac zawsze przed rozpoczeciem wavu
*/
native td_set_wave_info(iWave, e_WaveInfo:iInfo, _:iValue)

/* Zwraca informacje o graczu */
native td_get_user_info(iPlayer, e_Player:iInfo)

/* Ustawia informacje o graczu */
native td_set_user_info(iPlayer, e_Player:iInfo, iValue)

/* Zwraca typ potwora */
native e_RoundType:td_get_monster_type(iEnt)

/* Zwraca HP potwora */
native td_get_monster_health(iEnt)

/* Zwraca id[ent] healthbara potwora */
native td_get_monster_healthbar(iEnt)

/* Zwraca polozenie startu (resp potworow) */
native td_get_start_origin(Float:outOrigin[3])

/* Zwraca polozenie endu (tower) */
native td_get_end_origin(Float:outOrigin[3])

/* Zwraca nazwe rundy */
native td_get_round_name(e_RoundType:iRoundType, szOutpout[], len)

/* Zabija potwora przez gracza */
native td_kill_monster(iEnt, id)


/* ============================ */
/*           Forwardy           */
/* ============================ */

/* Wykonwywany przy rozpoczeciu wave'u */
forward td_startwave(iWave, e_RoundType:iMonsterType, iNum)

/* Wykonwywany przy zakonczeniu wave'u */
forward td_endwave(iWave)

/* Wykonywany przed zabiciem potwora */
forward td_monster_killed(iEnt, iPlayer, e_RoundType:iMonsterType)
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1045\\ f0\\ fs16 \n\\ par }
*/
