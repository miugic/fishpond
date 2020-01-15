#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

public Plugin:INFO =
{
	name = "teamkill-punishment",
	author = "slimfish",
	description = "punish team-killer",
	version = "1.0",
	url = "i.slimfish.net"
};

public OnPluginStart() {
	HookEvent("player_death", Event_PlayerDeath);
}

public bool IsValidPlayer(int client)
{
	if(client > 0 && client <= MaxClients && IsClientInGame(client) && !IsFakeClient(client))
	{
		return true;
	}
	return false;
}

public Action Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast) {
    int attacker = event.GetInt("attacker");
	int attackerClient = GetClientOfUserId(attacker);
	int victim = event.GetInt("userid");
	int victimClient = GetClientOfUserId(victim);
	if(IsValidPlayer(victimClient) && IsValidPlayer(attackerClient))
	{
        if(GetClientTeam(attackerClient) == GetClientTeam(victimClient) && victim != attacker && IsPlayerAlive(attackerClient))
        {
			SlapPlayer(attackerClient, 1000);
        }
    }
	return Plugin_Continue;
}