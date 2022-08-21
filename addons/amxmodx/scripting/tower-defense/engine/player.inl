#if defined td_engine_player_includes
  #endinput
#endif
#define td_engine_player_includes

public onPlayerKilledMonster(playerId, bool:isByHeadshot)
{
    addPlayerFrags(playerId, .amount = 1);

    createPlayerKilledIcon(playerId, isByHeadshot);
}