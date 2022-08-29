#if defined td_engine_player_kills_includes
  #endinput
#endif
#define td_engine_player_kills_includes

public addPlayerFrags(id, amount)
{
    fm_set_user_frags(id, get_user_frags(id) + amount);

    @refreshPlayerFrags(id);
}

public createPlayerKilledIcon(id, bool: isHeadShot, bool:isKilledByPlayer) 
{
    @makeDeathMsg(id, isHeadShot, .isByGrenade = false, .isKilledByPlayer = isKilledByPlayer);
}

@refreshPlayerFrags(id)
{
    static scoreMessageId;
    if (!scoreMessageId) scoreMessageId = get_user_msgid("ScoreInfo");

    message_begin(MSG_ALL, scoreMessageId, {0,0,0}, 0);
    write_byte(id);
    write_short(get_user_frags(id));
    write_short(cs_get_user_deaths(id));
    write_short(0);
    write_short(_:cs_get_user_team(id));
    message_end();
}

@makeDeathMsg(id, bool:isHeadshot, bool:isByGrenade, bool:isKilledByPlayer)
{
    static deathMessageId;
    if(!deathMessageId) deathMessageId = get_user_msgid("DeathMsg");

    new weaponName[24];
    new weaponId = get_user_weapon(id);
    
    if(isByGrenade)
    {
        formatex(weaponName, 23, "grenade");
    }
    else if (!isKilledByPlayer)
    {
        formatex(weaponName, 23, "")
    }
    else
    {
        get_weaponname(weaponId, weaponName, 23)	
        replace(weaponName, 23, "weapon_", EMPTY_STRING)
    }

    message_begin(MSG_ALL, deathMessageId, {0,0,0}, 0);
    write_byte(id);
    write_byte(0);
    write_byte(_:isHeadshot);
    write_string(weaponName);
    message_end();
}