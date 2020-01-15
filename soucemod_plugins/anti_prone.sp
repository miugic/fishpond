#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

public Plugin myinfo = 
{
	name = "anti_prone",
	author = "slimfish",
	description = "Anti prone.",
	version = "1.0",
	url = "i.slimfish.net"
}

public void OnPluginStart()
{
}

public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon, int& subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2])
{
	if(client > 0 && client <= MaxClients && IsClientInGame(client))
	{
		if (buttons & IN_FORWARD)
		{
			buttons &= ~IN_FORWARD;
			return Plugin_Changed;
		}
	}
    return Plugin_Continue;
}