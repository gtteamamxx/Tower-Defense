#if defined td_json_events_included
  #endinput
#endif
#define td_json_events_included

public registerClientCommands()
{
  register_clcmd("say /start", "@test");
  register_clcmd("say /nextwave", "@test2");
}

@test(id)
{
  new totalCount[2];
  if(!getWaveMonstersTotalCount(g_ActualWave, totalCount))
  {
    client_print(0, 3, "Brak wave: %d", g_ActualWave);
  }
  else
  {
    client_print(0, 3, "Wave: %d | %d - %d", g_ActualWave, totalCount[0], totalCount[1]);
  }
}

@test2(id)
{
  g_ActualWave++;
}
