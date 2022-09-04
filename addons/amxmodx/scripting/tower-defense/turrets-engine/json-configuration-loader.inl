#if defined _towerdefense_turrets_json_configuration_loader_included
  #endinput
#endif
#define _towerdefense_turrets_json_configuration_loader_included

public initializeConfigurationFromFile(configurationFilePath[128])
{
    log_amx("[TURRETS] Loading turrets configuration from file: %s", configurationFilePath);

    // load json file
    new JSON:json = json_parse(configurationFilePath, .is_file = true, .with_comments = true);

    // load turrets key
    new JSON:turretsJson = json_object_get_value(json, TURRETS_SCHEMA)

    // if it's not json object don't load
    if (!json_is_object(turretsJson)) 
    {
        log_amx("[TURRETS] %s is not object or does not exists", TURRETS_SCHEMA);
    } 
    else 
    {
        // load all configuration from specified key
        @loadConfigurationToDictionary(turretsJson);
    }
    
    // free json handle
    json_free(turretsJson);
    json_free(json);
}

@loadConfigurationToDictionary(JSON:turretsJson)
{
    new numberOfTurretsConfigured = json_object_get_count(turretsJson);

    // just for log
    if (numberOfTurretsConfigured == 0) 
    {
        log_amx("[TURRETS] No defined turrets");
    }

    // loop through all turrets configured in json file
    for(new i = 0; i < numberOfTurretsConfigured; ++i)
    {
        // get turret name
        new turretName[33];
        json_object_get_name(turretsJson, i, turretName, 32);

        // get json array
        new JSON:turretJson = json_object_get_value(turretsJson, turretName);

        // if it's not an object don't do anything
        if (!json_is_object(turretJson)) 
        {
            log_amx("[TURRETS] %s.%s is not object", TURRETS_SCHEMA, turretName);
        }
        else
        {
            @loadTurretInfo(turretJson, turretName);
        }

        // free resources
        json_free(turretJson);
    }
}

@loadTurretInfo(JSON:turretJson, turretName[33])
{
    new numberOfConfigurations = json_object_get_count(turretJson);
    new requiredConfigurationsCount = _:TURRET_INFO;

    // if configuration provided for turret doesn't have
    // all informations then turret would not work so we can't load then
    if (numberOfConfigurations != _:requiredConfigurationsCount)
    {
        log_amx("[TURRETS] %s.%s.{} has invalid length (invalid number of configuration). %d / %d", TURRETS_SCHEMA, turretName, numberOfConfigurations, requiredConfigurationsCount);
        return;
    }

    // init configuration for turret
    new Array:turretInfoArray = @createAndConfigurationArrayForTurret(turretName);

    // loop through all configurations
    for(new i; i < numberOfConfigurations; i = ++i) 
    {
        // get config name
        new configName[33];
        json_object_get_name(turretJson, i, configName, 32);

        new JSON:configurationJson = JSON:json_object_get_value(turretJson, configName);
        
        // if is 'skills' property
        if (equali(configName, SKILLS_SCHEMA))
        {
            @loadSkillsForTurret(configurationJson, turretInfoArray);
        }
        // if config value is number
        else if (json_is_number(configurationJson))
        {
            @loadTurretPropertyNumber(JSON:configurationJson, Array:turretInfoArray, configName);
        }
        else
        {
            log_amx("[TURRETS] %s.%s.%s is not valid config. Type mismatch maybe?", TURRETS_SCHEMA, turretName, configName);
        }

        // free resources
        json_free(configurationJson);
    }
}

@loadSkillsForTurret(JSON:skillsJson, Array:turretInfoArray)
{
    new loadedSkillsCount = json_object_get_count(skillsJson);
    new skillsCount = _:TURRET_SKILLS;

    // if skills provided for turret doesn't have
    // all informations then turret would not work so we can't load then
    if (loadedSkillsCount != _:skillsCount)
    {
        log_amx("[TURRETS] %s.%s.{} has invalid length (invalid number of skills). %d / %d", SKILLS_SCHEMA, turretName, loadedSkillsCount, skillsCount);
        return;
    }

    // create skills array
    Array:turretSkillsArray = @createSkillsArrayForTurret(turretInfoArray);
    
    // loop through skill properties
    for(new i; i < skillsCount; i = ++i) 
    {
        // get skill name
        new skillName[33];
        json_object_get_name(turretJson, i, skillName, 32);

        // get skill json with properties
        new JSON:skillJson = JSON:json_object_get_value(skillsJson, skillName);

        // get skill index in array by skill name
        new skillIndex = getArrayTurretInfoIndex(skillName);
        
        // get skill array for skill with filled properties from json
        new Array:skillArray = @getSkillArrayFromJson(skillName, skillJson);

        // save skill properties
        ArraySetCell(turretSkillsArray, skillIndex, skillArray);

        // free memory
        json_free(skillJson);
    }
}


Array:@getSkillArrayFromJson(skillName[33], JSON:skillJson)
{
    new loadedSkillPropertiesCount = json_object_get_count(skillJson);
    new skillPropertiesCount = _:TURRET_SKILL_INFO;

    // if skills provided for turret doesn't have
    // all informations then turret would not work so we can't load then
    if (loadedSkillPropertiesCount != _:skillPropertiesCount)
    {
        log_amx("[TURRETS] %s.{} has invalid length (invalid number of skill properties). %d / %d", skillName, loadedSkillsCount, skillsCount);
        return;
    }

    new Array:skillArray = ArrayCreate();

    // Get and set upgrade points value to array
    new JSON:upgradePointsJson = JSON:json_object_get_value(skillJson, UPGRADE_POINTS_SCHEMA);
    new Float:upgradePointsValue = json_get_real(upgradePointsJson);

    ArrayPushCell(skillArray, _:UPGRADE_POINTS, upgradePointsValue);

    // Get and set levels array
    new JSON:levelsJson = JSON:json_object_get_value(skillJson, LEVELS_SCHEMA);

    // load configuration data
    @loadConfigurationInfo(levelsJson, configurationArray);

    levelValues[0] = json_array_get_real(levelJson, 0);

    // free memory
    json_free(upgradePointsJson);
    json_free(levelsJson);
}

Array:@createSkillsArrayForTurret(Array:turretInfoArray)
{
    // get configured previously turret skills array
    // to append skills arrays
    new Array:turretSkillsArray = Array:ArrayGetCell(turretInfoArray, _:TURRET_SKILLS);

    return turretSkillsArray;
}

Array:@createAndConfigurationArrayForTurret(turretKey[33])
{
    // create configuration key with turret name
    new Array:turretInfoArray = ArrayCreate();

    // create and fill configuration array 
    for(new i = 0; i < _:TURRET_INFO; ++i)
    {
        if (TURRET_INFO:i == TURRET_MAX_COUNT
        || TURRET_INFO:i == TURRET_ACTIVATION_TIME
        || TURRET_INFO:i == TURRET_RELOAD_TIME
        || TURRET_INFO:i == TURRET_UPGRADE_TIME
        || TURRET_INFO:i == TURRET_START_AMMO
        || TURRET_INFO:i == TURRET_RELOAD_AMMO) 
        {
            ArrayPushCell(turretInfoArray, 0.0);
        }
        // If it is 'skills' index, we need to create new array
        else if (TURRET_INFO:i == TURRET_SKILLS)
        {
            new Array:turretSkillsInfoArray = ArrayCreate();
            ArrayPushCell(turretInfoArray, turretSkillsInfoArray);
        }
    }

    TrieSetCell(g_TurretInfoTrie, turretKey, turretInfoArray);

    return turretInfoArray;
}

@loadTurretPropertyNumber(JSON:configurationJson, Array:turretInfoArray, configName[33])
{
    // get number value
    new Float:value = json_get_real(configurationJson);
    
    new key = -1;

    if (equali(configName, MAX_COUNT_SCHEMA)) key = _:TURRET_MAX_COUNT;
    else if (equali(configName, ACTIVATION_TIME_SCHEMA)) key = _:TURRET_ACTIVATION_TIME;
    else if (equali(configName, RELOAD_TIME_SCHEMA)) key = _:TURRET_RELOAD_TIME;
    else if (equali(configName, UPGRADE_TIME_SCHEMA)) key = _:TURRET_UPGRADE_TIME;
    else if (equali(configName, START_AMMO_SCHEMA)) key = _:TURRET_START_AMMO;
    else if (equali(configName, RELOAD_AMMO_SCHEMA)) key = _:TURRET_RELOAD_AMMO;

    // if key was found
    if (key != -1) 
    {
        // set value
        ArraySetCell(turretInfoArray, key, value);
    }
    else
    {
        log_amx("[TURRETS] Undefined config key: %s", configName);
    }
}

@loadLevelsForTurret(JSON:levelsJson, Array:configurationArray)
{
    new numberOfLevels = json_array_get_count(levelsJson);

    // loop through all levels
    for(new level = 0; level < numberOfLevels; ++level)
    {
        new JSON:levelJson = json_array_get_value(levelsJson, level);

        // if its not an array don't do anything
        if (!json_is_array(levelJson))
        {
            log_amx("[TURRETS] %s.%s.%s.[%d] is not array", LEVELS_SCHEMA, turretName, configName, level);
        }
        else
        {
            // get number of level values
            new levelDataCount = json_array_get_count(levelJson);
            
            // if invalid number of values is provided don't do anything
            if (levelDataCount == 0 || levelDataCount > 2)
            {
                log_amx("[TURRETS] %s.%s.%s[%d] should have 1-2 float values", TURRETS_SCHEMA, turretName, configName, level);
            }
            else
            {
                // load level values
                new Float:levelValues[2];
                levelValues[0] = json_array_get_real(levelJson, 0);

                if (levelDataCount == 2) 
                {
                    levelValues[1] = json_array_get_real(levelJson, 1);
                }

                // fill level array
                ArrayPushArray(configurationArray, levelValues);
            }
        }

        // free json handle
        json_free(levelJson);        
    }
}

@getArrayTurretSkillInfoIndex(configName[33])
{
    if (equali(configName, LEVELS_SCHEMA)) return _:LEVELS;
    if (equali(configName, UPGRADE_POINTS_SCHEMA)) return _:UPGRADE_POINTS;
}

@getArrayTurretInfoIndex(configName[33])
{
    if (equali(configName, DAMAGE_SCHEMA)) return _:SKILL_DAMAGE;
    if (equali(configName, RANGE_SCHEMA)) return _:SKILL_RANGE;
    if (equali(configName, FIRERATE_SCHEMA)) return _:SKILL_FIRERATE;
    if (equali(configName, ACCURACY_SCHEMA)) return _:SKILL_ACCURACY;
    if (equali(configName, AGILITY_SCHEMA)) return _: SKILL_AGILITY;

    return -1;
}