public Plugin myinfo = 
{
	name = "kill_effects",
	author = "slimfish",
	description = "kill effects",
	version = "1.0",
	url = "i.slimfish.net"
}

#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#define	HITGROUP_GENERIC	0
#define	HITGROUP_HEAD		1
#define	HITGROUP_CHEST		2
#define	HITGROUP_STOMACH	3
#define HITGROUP_LEFTARM	4	
#define HITGROUP_RIGHTARM	5
#define HITGROUP_LEFTLEG	6
#define HITGROUP_RIGHTLEG	7
#define HITGROUP_GEAR		10

public void OnPluginStart()
{
	HookEvent("player_hurt", Event_PlayerHurt);
}

public Action Event_PlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
	//	"userid"		"short"
	//	"weapon"		"string"
	//	"hitgroup"		"short"
	//	"priority"		"short"
	//	"attacker"		"short"
	//	"dmg_health"	"short"
	//	"health"		"byte"
	
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	if(attacker > 0 && attacker <= MaxClients && !IsFakeClient(attacker) && IsClientInGame(attacker))
	{
		if(GetClientTeam(GetClientOfUserId(event.GetInt("userid"))) != GetClientTeam(attacker))
		{
			if(event.GetInt("health") == 0)
			{
				CreateTimer(0.1, Timer_PlayKillSound, event.GetInt("attacker"), TIMER_FLAG_NO_MAPCHANGE);
				// if(event.GetInt("hitgroup") == HITGROUP_HEAD)
				// {
				// 	int attackerHealth = GetClientHealth(attacker);
				// 	if(attackerHealth <= 80) {
				// 		PrintHintText(attacker, "Headshot! HP: %d -> %d", attackerHealth, attackerHealth+20);
				// 		attackerHealth = attackerHealth + 20;
				// 	}else if(attackerHealth < 100){
				// 		PrintHintText(attacker, "Headshot! HP: %d -> %d", attackerHealth, 100);
				// 		attackerHealth = 100;
				// 	}else{
				// 		PrintHintText(attacker, "Headshot! HP: %d", attackerHealth);
				// 	}
				// 	SetEntityHealth(attacker, attackerHealth);
				// }
			}
		}
		
	}
	return Plugin_Continue;
}
public Action Timer_PlayKillSound(Handle timer,int userid)
{
	int client = GetClientOfUserId(userid);
	if(client > 0 && client <= MaxClients && IsClientInGame(client) && !IsFakeClient(client))
	{
		ClientCommand(client, "play custom/player/bf1_kill.wav"); //play battlefield 1 kill sound.
	}
}