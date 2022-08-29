#include <amxmodx>
#include <td_turrets>
#include <engine>
#include <td>

#define PLUGIN "Tower Defense Turret: Bullet"
#define VERSION "1.0"
#define AUTHOR "GT Team"

#pragma semicolon 1

#define TURRET_KEY "BULLET"
#define TURRET_NAME "Bullet"

#define FIRE_SOUND_1 "TDNew//bullet_fire_new_1.wav"
#define FIRE_SOUND_2 "TDNew//bullet_fire_new_2.wav"
#define SHELL_SPRITE_MODEL "models/rshell_big.mdl"

new g_SpriteShell;

public plugin_init() 
{
    register_plugin(PLUGIN, VERSION, AUTHOR);

    td_register_turret(TURRET_KEY, TURRET_NAME);
}

public plugin_precache()
{
    precache_sound(FIRE_SOUND_1);
    precache_sound(FIRE_SOUND_2);

    g_SpriteShell = precache_model(SHELL_SPRITE_MODEL);
}

public td_on_turret_created(ent, id)
{
}

public td_on_turret_low_ammo(ent, id)
{
}

public td_on_turret_no_ammo(ent, id)
{
}

public td_on_turret_shot_miss(ent, monster, id)
{
    @showShotEffect(ent, monster, .miss = true);
    @emitShotSound(ent);
}

public td_on_turret_shot(ent, monster, id, Float:damage)
{
    @showShotEffect(ent, monster, .miss = false);
    @emitShotSound(ent);

    td_take_monster_damage(id, monster, damage, DMG_DROWN);
}

public td_on_turret_start_fire(ent, monster, id)
{
}

public td_on_turret_stop_fire(ent, id)
{
}

@showShotEffect(ent, monster, bool:miss)
{
    new Float:fTurretOrigin[3];
    new Float:fTargetOrigin[3];

    new iTurretOrigin[3];
    new iTargetOrigin[3];

    entity_get_vector(monster, EV_VEC_origin, fTargetOrigin);
    entity_get_vector(ent, EV_VEC_origin, fTurretOrigin);

    fTurretOrigin[2] += 45;

    FVecIVec(fTurretOrigin, iTurretOrigin);
    FVecIVec(fTargetOrigin, iTargetOrigin);

	/* Make fire */
    new targetOriginY = random_num(iTargetOrigin[2] - 20, iTargetOrigin[2] + 30);

    // miss fire top or bottom    
    if (miss)
    {
        switch(random_num(1, 2))
        {
            case 1: targetOriginY += random_num(70, 90);
            case 2: targetOriginY += random_num(-70, -90);
        }
    }
    
    message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
    write_byte(TE_TRACER);
    write_coord(iTurretOrigin[0]);
    write_coord(iTurretOrigin[1]);
    write_coord(iTurretOrigin[2]);
    write_coord(iTargetOrigin[0]);
    write_coord(iTargetOrigin[1]);
    write_coord(targetOriginY);
    message_end();
    
    /* Make shell */
    message_begin(MSG_BROADCAST, SVC_TEMPENTITY, {0.0, 0.0, 0.0}, ent);
    write_byte(TE_MODEL);
    write_coord(iTurretOrigin[0]);
    write_coord(iTurretOrigin[1]);
    write_coord(iTurretOrigin[2]);
    write_coord(random_num(-100,100));
    write_coord(random_num(-100,100));
    write_coord(random_num(100,200));
    write_angle(random_num(0,360));
    write_short(g_SpriteShell);
    write_byte(0);
    write_byte(100);
    message_end();
}

@emitShotSound(ent)
{
    switch(random_num(1, 2))
    {
        case 1: emit_sound(ent, CHAN_AUTO, FIRE_SOUND_1, 1.0, ATTN_NORM, 0, PITCH_NORM);
        case 2: emit_sound(ent, CHAN_AUTO, FIRE_SOUND_2, 1.0, ATTN_NORM, 0, PITCH_NORM);
    }
}