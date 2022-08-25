#if defined _towerdefense_turrets_player_commands_included
  #endinput
#endif
#define _towerdefense_turrets_player_commands_included

public registerPlayerCommands()
{
    register_clcmd("say /turrets", "openTurretsMenu");
}