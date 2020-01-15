#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <geoip>

public Plugin myinfo = 
{
	name = "print_country",
	author = "slimfish",
	description = "print connected from which country",
	version = "1.0",
	url = "i.slimfish.net"
}

public void OnPluginStart()
{
}
bool IsValidPlayer(int client)
{
	if(client > 0 && client <= MaxClients && IsClientInGame(client) && !IsFakeClient(client))
	{
		return true;
	}
	return false;
}
public void OnClientPostAdminCheck(int client)
{
	if(IsValidPlayer(client)){
		char ip[16];
		char country[30];
		char name[32];
		GetClientIP(client, ip, sizeof(ip));
		GetClientName(client, name,sizeof(name));
		GeoipCountry(ip, country, sizeof(country));
		PrintToChatAll("\x0766cccc%s connected from %s",name,country);
	}
}
