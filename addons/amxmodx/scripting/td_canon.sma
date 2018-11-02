#include <amxmodx>
#include <amxmisc>
#include <fakemeta_util>
#include <hamsandwich>
#include <td>
#include <engine>

new const SOUND_ATTACK[] 	= "TD/ic_attack.wav"
new const SOUND_READY[] 	= "TD/ic_ready.wav"

new BlueFire, 
LaserFlame, 
IonBeam, 
Shockwave, 
BlueFlare,
IonShake,
ent,
Float:g_fBeamOrigin[8][3],
Float:g_fBeamMidOrigin[3],
Float:g_fRotationSpeed,
Float:g_fDegrees[8],
Float:g_fDistance

new shop_item

new g_PlayerUse[33]

public plugin_init() 
{
	new plugin = register_plugin("IonCannon", "1.0", "MarWit");
	shop_item = td_shop_register_item("Canon", "Press 'C' to use canon", 500, 0, plugin);
	IonShake = get_user_msgid("ScreenShake")
	register_clcmd("radio3", "CmdUseCanon");
}


public CmdUseCanon(id)
{
	if(!g_PlayerUse[id])
		return PLUGIN_HANDLED;
	
	g_PlayerUse[id]--;
	FireCannon(id);

	return PLUGIN_HANDLED;
}

public client_disconnected(id)
	g_PlayerUse[id] = 0;

public td_shop_item_selected(id, item)
{
	if(item == shop_item)
	{
		client_print(id, print_center, "Press 'C' somewhere you want to use canon.");
		g_PlayerUse[id]++;
	}
}
public plugin_precache()
{
	LaserFlame = precache_model("sprites/TD/ic_laserflame.spr");
	IonBeam = precache_model("sprites/TD/ic_ionbeam.spr");
	Shockwave = precache_model("sprites/shockwave.spr")
	BlueFlare = precache_model("sprites/TD/ic_bflare.spr")
	
	engfunc(EngFunc_PrecacheSound, SOUND_ATTACK)
	engfunc(EngFunc_PrecacheSound, SOUND_READY)
}

public td_game_ended(iEndResult)
{
	if(iEndResult == PLAYERS_LOSE)
		CreateIon();
}

public CreateIon()
{
	ent = engfunc(EngFunc_CreateNamedEntity,engfunc(EngFunc_AllocString,"info_target"));
	set_pev(ent,pev_classname,"info_target_ion");
	set_pev(ent,pev_movetype, MOVETYPE_TOSS);
	set_pev(ent,pev_solid, SOLID_TRIGGER);
	
	StartPosition(0, 0, -30);
	set_pev(ent,pev_origin,g_fBeamMidOrigin);
	
	StartUp();
}

public StartUp()
{
	new Float:mid_origin[3], Float:fTmpDegress = 0.0;
	
	pev(ent, pev_origin,mid_origin);
	
	g_fDistance = 190.5 * 1.85;
	g_fRotationSpeed = 0.0;
	
	for(new i = 1; i < 8; i++)
	{
		g_fDegrees[i] = fTmpDegress;
		fTmpDegress += 45.0;
	}
	
	g_fBeamOrigin[0][0] = mid_origin[0] + 300.0
	g_fBeamOrigin[1][0] = mid_origin[0] + 300.0
	g_fBeamOrigin[2][0] = mid_origin[0] - 300.0
	g_fBeamOrigin[3][0] = mid_origin[0] - 300.0
	g_fBeamOrigin[4][0] = mid_origin[0] + 150.0
	g_fBeamOrigin[5][0] = mid_origin[0] + 150.0
	g_fBeamOrigin[6][0] = mid_origin[0] - 150.0
	g_fBeamOrigin[7][0] = mid_origin[0] - 150.0
	
	g_fBeamOrigin[0][1] = mid_origin[1] + 150.0
	g_fBeamOrigin[1][1] = mid_origin[1] - 150.0
	g_fBeamOrigin[2][1] = mid_origin[1] - 150.0
	g_fBeamOrigin[3][1] = mid_origin[1] + 150.0
	g_fBeamOrigin[4][1] = mid_origin[1] + 300.0
	g_fBeamOrigin[5][1] = mid_origin[1] - 300.0
	g_fBeamOrigin[6][1] = mid_origin[1] - 300.0
	
	g_fBeamMidOrigin = mid_origin
	
	for(new i = 0; i < 8; i++) 
	{
		static Float:addtime; addtime = addtime + 0.3
		new param[2]
		param[0] = i
		set_task(0.0 + addtime, "Trace_Start", _,param, 1)
	}
	
	client_cmd(0, "spk ^"%s^"", SOUND_READY)
	
	BeamRotate()
	
	for(new Float:i = 0.0; i < 7.5; i += 0.01)
		set_task(i+3.0, "BeamRotate")
	
	set_task(2.9,"IncreaseSpeed")
	set_task(12.5,"RemoveLasers")
	set_task(15.2,"FireCannon", 0)
}

public IncreaseSpeed() 
{
	if(g_fRotationSpeed > 1.0) 
		g_fRotationSpeed = 1.0
	
	g_fRotationSpeed += 0.1
	
	set_task(0.6,"IncreaseSpeed")
	
	return;
}

public RemoveLasers(id) 
    remove_task(1018+id)

public BeamRotate()
{
	g_fDistance -= 0.467
	//g_distance[id] -= 0.254
	for(new i = 0; i < 8; i++) 
	{
		g_fDegrees[i] += g_fRotationSpeed
		
		if(g_fDegrees[i] > 360.0)
			g_fDegrees[i] -= 360.0
		
		static Float:tmp[3]
		tmp = g_fBeamMidOrigin
		
		tmp[0] += floatsin(g_fDegrees[i], degrees) * g_fDistance
		tmp[1] += floatcos(g_fDegrees[i], degrees) * g_fDistance 
		tmp[2] += 0.0 // -.-
		g_fBeamOrigin[i] = tmp
	}
}

public Trace_Start(param[]) 
{
	new i = param[0]
	
	new Float:get_random_z, Float:SkyOrigin[3]
	
	SkyOrigin = tlx_distance_to_sky(ent)
	
	get_random_z = random_float(300.0,SkyOrigin[2])
	
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, g_fBeamOrigin[i], 0)
	write_byte(TE_SPRITE)
	engfunc(EngFunc_WriteCoord, g_fBeamOrigin[i][0])
	engfunc(EngFunc_WriteCoord, g_fBeamOrigin[i][1])
	engfunc(EngFunc_WriteCoord, g_fBeamOrigin[i][2] + get_random_z)
	write_short(BlueFire)
	write_byte(10)
	write_byte(100)
	message_end()
	
	TraceAll(param)
}

public TraceAll(param[]) 
{
	new i = param[0]
	
	new Float:SkyOrigin[3]
	SkyOrigin = tlx_distance_to_sky(ent)
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, g_fBeamOrigin[i], 0)
	write_byte(TE_BEAMPOINTS)
	engfunc(EngFunc_WriteCoord, g_fBeamOrigin[i][0])		//start point (x)
	engfunc(EngFunc_WriteCoord, g_fBeamOrigin[i][1])		//start point (y)
	engfunc(EngFunc_WriteCoord, SkyOrigin[2])			//start point (z)
	
	engfunc(EngFunc_WriteCoord, g_fBeamOrigin[i][0])		//end point (x)
	engfunc(EngFunc_WriteCoord, g_fBeamOrigin[i][1])		//end point (y)
	engfunc(EngFunc_WriteCoord, g_fBeamOrigin[i][2])		//end point (z)
	write_short(IonBeam)	//model
	write_byte(0)		//startframe
	write_byte(0)		//framerate
	write_byte(1)		//life
	write_byte(50)		//width
	write_byte(0)		//noise
	write_byte(255)		//r
	write_byte(255)		//g
	write_byte(255)		//b
	write_byte(255)		//brightness
	write_byte(0)		//speed
	message_end()
	
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, g_fBeamOrigin[i], 0)
	write_byte(TE_SPRITE)
	engfunc(EngFunc_WriteCoord, g_fBeamOrigin[i][0])
	engfunc(EngFunc_WriteCoord, g_fBeamOrigin[i][1])
	engfunc(EngFunc_WriteCoord, g_fBeamOrigin[i][2])
	write_short(LaserFlame)
	write_byte(5)
	write_byte(200)
	message_end()
	
	set_task(0.08,"TraceAll", 1018, param, 2)
}


public FireCannon(id) 
{
	new i = -1
	new className[33]
	while((i = engfunc(EngFunc_FindEntityInSphere, i, g_fBeamMidOrigin, 10000.0)) != 0) 
	{
		pev(i, pev_classname, className, 32)
		
		if(pev_valid(i) && equal(className, "player")) 
		{
			message_begin(MSG_ONE, IonShake, {0,0,0}, i)
			write_short(255<<14)
			write_short(10<<14) 
			write_short(255<<14) 
			message_end()
		}
		
		continue
	}
	
	new Float:skyOrigin[3], Float:fEntOrigin[3], ent2;
	
	if(id == 0)
	{
		skyOrigin = tlx_distance_to_sky(ent)
		pev(ent, pev_origin, fEntOrigin);
	}
	else
	{
		ent2 = engfunc(EngFunc_CreateNamedEntity,engfunc(EngFunc_AllocString,"info_target"));
		set_pev(ent2,pev_classname,"info_target_ion");
		set_pev(ent2,pev_movetype, MOVETYPE_TOSS);
		set_pev(ent2,pev_solid, SOLID_TRIGGER);
		
		new Origin[3]
		get_user_origin(id, Origin, 3);
		IVecFVec(Origin, fEntOrigin);
		set_pev(ent2,pev_origin,fEntOrigin);
		
		skyOrigin = tlx_distance_to_sky(ent2);
	}
	
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, g_fBeamMidOrigin, 0)
	write_byte(TE_BEAMPOINTS) 
	engfunc(EngFunc_WriteCoord, skyOrigin[0])	//start point (x)
	engfunc(EngFunc_WriteCoord, skyOrigin[1])	//start point (y)
	engfunc(EngFunc_WriteCoord, skyOrigin[2])	//start point (z)
	
	engfunc(EngFunc_WriteCoord, fEntOrigin[0])		//end point (x)
	engfunc(EngFunc_WriteCoord, fEntOrigin[1])		//end point (y)
	engfunc(EngFunc_WriteCoord, fEntOrigin[2])		//end point (z)
	write_short(IonBeam)	//model
	write_byte(0)		//startframe
	write_byte(0)		//framerate
	write_byte(15)		//life
	write_byte(255)		//width
	write_byte(0)		//noise
	write_byte(255)		//r
	write_byte(255)		//g
	write_byte(255)		//b
	write_byte(255)		//brightness
	write_byte(0)		//speed
	message_end()
	
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY,g_fBeamMidOrigin, 0)
	write_byte(TE_BEAMCYLINDER)
	engfunc(EngFunc_WriteCoord, fEntOrigin[0]) // start X
	engfunc(EngFunc_WriteCoord, fEntOrigin[1]) // start Y
	engfunc(EngFunc_WriteCoord, fEntOrigin[2]) // start Z
	
	engfunc(EngFunc_WriteCoord, fEntOrigin[0]) // something X
	engfunc(EngFunc_WriteCoord, fEntOrigin[1]) // something Y
	engfunc(EngFunc_WriteCoord, fEntOrigin[2] + 2000.0 - 1000.0) // something Z
	write_short(Shockwave) // sprite
	write_byte(0) // startframe
	write_byte(0) // framerate
	write_byte(100) // life
	write_byte(150) // width
	write_byte(0) // noise
	write_byte(0) // red
	write_byte(100) // green
	write_byte(250) // blue
	write_byte(150) // brightness
	write_byte(0) // speed
	message_end()
	
	for(new i = 1; i < 6; i++) 
	{
		engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, g_fBeamMidOrigin, 0)
		write_byte(TE_SPRITETRAIL)	// line of moving glow sprites with gravity, fadeout, and collisions
		engfunc(EngFunc_WriteCoord, fEntOrigin[0])
		engfunc(EngFunc_WriteCoord, fEntOrigin[1])
		engfunc(EngFunc_WriteCoord, fEntOrigin[2])
		engfunc(EngFunc_WriteCoord, fEntOrigin[0])
		engfunc(EngFunc_WriteCoord, fEntOrigin[1])
		engfunc(EngFunc_WriteCoord, fEntOrigin[2] + 200)
		write_short(BlueFlare) // (sprite index)
		write_byte(50) // (count)
		write_byte(random_num(27,30)) // (life in 0.1's)
		write_byte(10) // byte (scale in 0.1's)
		write_byte(random_num(30,70)) // (velocity along vector in 10's)
		write_byte(40) // (randomness of velocity in 10's)
		message_end()
	}
	
	client_cmd(0, "spk ^"%s^"", SOUND_ATTACK)
	
	if(id == 0)
	{
		set_pev(ent, pev_flags, FL_KILLME)
		remove_entity(ent);
	}
	else
	{
		new entlist[25]
		new num = find_sphere_class(ent2, "monster", 2500.0, entlist, 25);
		
		for(new i = 0 ; i < num ; i++)
		{
			if(entlist[i] == 0)
				continue;
			
			if(entity_get_float(entlist[i], EV_FL_health) - 4500.0 <= 0.0)
				makeDeathMsg(id);
			
			ExecuteHamB(Ham_TakeDamage, entlist[i], id, id, 4500.0, DMG_BLAST)
		}
		set_pev(ent2, pev_flags, FL_KILLME)
		remove_entity(ent2);
	}
}
makeDeathMsg(iPlayer)
{
	static dmsg
	if(!dmsg)
		dmsg = get_user_msgid("DeathMsg");
	
	message_begin(MSG_ALL, dmsg, {0,0,0}, 0);
	write_byte(iPlayer);
	write_byte(0);
	write_byte(0);
	write_string("")
	message_end()
}

public StartPosition(forw, right, up)
{
	new Float:vOrigin[3] ,Float:vForward[3], Float:vRight[3], Float:vUp[3], Float:vSrc[3]
	
	td_get_end_origin(vOrigin);
	
	global_get(glb_v_forward, vForward)
	global_get(glb_v_right, vRight)
	global_get(glb_v_up, vUp)
	
	vSrc[0] = vOrigin[0] + vForward[0] * forw + vRight[0] * right + vUp[0] * up
	vSrc[1] = vOrigin[1] + vForward[1] * forw + vRight[1] * right + vUp[1] * up
	vSrc[2] = vOrigin[2] + vForward[2] * forw + vRight[2] * right + vUp[2] * up
	
	g_fBeamMidOrigin[0] = vSrc[0]
	g_fBeamMidOrigin[1] = vSrc[1]
	g_fBeamMidOrigin[2] = vSrc[2]
}


stock Float:tlx_distance_to_sky(id)
{
	new Float:TraceEnd[3]
	pev(id, pev_origin, TraceEnd)
	
	new Float:f_dest[3]
	f_dest[0] = TraceEnd[0]
	f_dest[1] = TraceEnd[1]
	f_dest[2] = TraceEnd[2] + 8192.0
	
	new res, Float:SkyOrigin[3]
	engfunc(EngFunc_TraceLine, TraceEnd, f_dest, IGNORE_MONSTERS + IGNORE_GLASS, id, res)
	get_tr2(res, TR_vecEndPos, SkyOrigin)
	
	return SkyOrigin
}

