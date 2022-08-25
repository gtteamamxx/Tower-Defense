#if defined _towerdefense_turrets_td_events_included
  #endinput
#endif
#define _towerdefense_turrets_td_events_included

public td_on_configuration_load(configurationFilePath[128], bool:isGamePossible)
{
    // if game is not possible we don't have to load json config
    if (!isGamePossible)
    {
        return;
    }

    @loadTurretsConfiguration(configurationFilePath);
}

@loadTurretsConfiguration(configurationFilePath[128])
{
    // load turrets config from json file
    initializeConfigurationFromFile(configurationFilePath);

    // if no turrets loaded try load from default config file
    if(getNumberOfLoadedTurrets() == 0)
    {
        formatex(configurationFilePath, 127, "%s/%s.json", CONFIG_DIRECTORY, DEFAULT_CONFIG_FILE);

        initializeConfigurationFromFile(configurationFilePath);

        // if after loading default config file no turrets configuration
        if(getNumberOfLoadedTurrets() == 0)
        {
            log_amx("[TURRETS] No loaded turrets");
        }
    }
}