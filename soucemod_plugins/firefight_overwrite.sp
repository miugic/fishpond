#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define NO_TEAM 0
#define TEAM_SPEC 1
#define TEAM_SEC 2
#define TEAM_INS 3
#define TEAM_ALL 4

ConVar gCvarIgnoreWin;    			//Ignore round win conditions.
ConVar gCvarIgnoreTimer;  			//Ignore round timer conditions.
ConVar gCvarFFTkCountMax;    		//If a player's team-killing count reachs the number then kick.
ConVar gCvarFFWinScore;  			//If a team reach the score, then win the round.
ConVar gCvarFFRespawnTime;  		//Before a respawn, must wait the value of time in seconds.
ConVar gCvarFFProtectTime;  		//Before a respawn, must wait the value of time in seconds.
ConVar gCvarFFTkPunishTime;  		//A tker has to wait the time in seconds before a respawn.
ConVar gCvarFFObserverRespawnTime;  //If a player changed his role from observer to a squad member, must wait the value of time in seconds to respawn.

Handle gGameConfigHandle;
Handle gForcePlayerRespawnHandle;
Handle gKickedTkerPlayersHandle;

int gWinScore;
int gScoreSec;
int gScoreIns;
int gLoseTeam;
int gTkCountMax;
int gTkerId;
int gTkCount[MAXPLAYERS+1];

bool gIsTkerApologized[MAXPLAYERS+1];

float gRespawnTime;
float gProtectTime;
float gTkPunishTime;
float gObserverRespawnTime;

public Plugin myinfo = 
{
	name = "firefight_overwrite",
	author = "slimfish",
	description = "used for fishpond pvp servers",
	version = "1.0",
	url = "i.slimfish.net"
}

public void OnPluginStart()
{
	///////////////////////////////////////////↓ SPAWNING ↓////////////////////////////////////////////
	gGameConfigHandle = LoadGameConfigFile("insurgency.games");
	if (gGameConfigHandle == INVALID_HANDLE)
	{
		SetFailState("Fatal Error: Missing File \"insurgency.games\"!");
	}
	StartPrepSDKCall(SDKCall_Player);
	decl String:game[40];
	GetGameFolderName(game, sizeof(game));
	if (StrEqual(game, "insurgency"))
	{
		PrepSDKCall_SetFromConf(gGameConfigHandle, SDKConf_Signature, "ForceRespawn");
	}
	if (StrEqual(game, "doi"))
	{
		PrepSDKCall_SetFromConf(gGameConfigHandle, SDKConf_Virtual, "ForceRespawn");
	}
	gForcePlayerRespawnHandle = EndPrepSDKCall();
	game[0] = '\0';
	if (gForcePlayerRespawnHandle == INVALID_HANDLE)
	{
		SetFailState("Fatal Error: Unable to find signature for \"ForceRespawn\"!");
	}
	///////////////////////////////////////////↑ SPAWNING ↑////////////////////////////////////////////
	gCvarFFTkCountMax = CreateConVar("sm_ff_tk_count_max", "3", "If a player's team-killing count reachs the number then kick, default is 3");
	gCvarFFWinScore = CreateConVar("sm_ff_win_score", "100", "If a team reach the score, then win the round, default is 100.");
	gCvarFFRespawnTime = CreateConVar("sm_ff_respawn_time", "3.0", "Before a respawn, must wait the value of time in seconds, default is 3");
	gCvarFFProtectTime = CreateConVar("sm_ff_protect_time", "4.0", "Protect time in seconds for a respawned player, default is 4");
	gCvarFFObserverRespawnTime = CreateConVar("sm_ff_observer_respawn_time", "15.0", "If a player changed his role from observer to a squad member, must wait the value of time in seconds to respawn, default is 15");
	gCvarFFTkPunishTime = CreateConVar("sm_ff_tk_punish_time", "30.0", "A tker has to wait the time in seconds before a respawn, default is 30");

	HookEvent("round_start", Event_RoundStart);
	HookEvent("player_pick_squad", Event_PlayerPickSquad);
	HookEvent("player_death", Event_PlayerDeath);
}
public void OnConfigsExecuted()
{
	gCvarIgnoreWin = FindConVar("mp_ignore_win_conditions");
	gCvarIgnoreTimer = FindConVar("mp_ignore_timer_conditions");

	gWinScore = GetConVarInt(gCvarFFWinScore);
	gTkCountMax = GetConVarInt(gCvarFFTkCountMax);
	gRespawnTime = GetConVarFloat(gCvarFFRespawnTime);
	gProtectTime = GetConVarFloat(gCvarFFProtectTime);
	gTkPunishTime = GetConVarFloat(gCvarFFTkPunishTime);
	gObserverRespawnTime = GetConVarFloat(gCvarFFObserverRespawnTime);

	InitState();
}

public void ClearClientTkerStates(int client) 
{
	if(client > 0 && client <= MaxClients)
	{
		gTkCount[client] = 0;
		gIsTkerApologized[client] = false;
	}
}

public void RespawnPlayer(int userid)
{
	if(gLoseTeam == NO_TEAM)
	{
		int client = GetClientOfUserId(userid);
		if(IsValidPlayer(client))
		{
			if(IsClientInGame(client) && !IsPlayerAlive(client) && (GetClientTeam(client) == TEAM_SEC || GetClientTeam(client) == TEAM_INS))
			{
				SDKCall(gForcePlayerRespawnHandle, client);
				SetEntProp(client, Prop_Data, "m_takedamage", 0); //Enable god mode.
				CreateTimer(gProtectTime, Timer_DisableGodMode, userid, TIMER_FLAG_NO_MAPCHANGE);
			}
		}
	}
}

public void DisableGodMode(int userid)
{
	int client = GetClientOfUserId(userid);
	if(IsValidPlayer(client))
	{
		if(IsClientInGame(client) && (GetClientTeam(client) == TEAM_SEC || GetClientTeam(client) == TEAM_INS))
		{
			SetEntProp(client, Prop_Data, "m_takedamage", 2); //Disable god mode.
		}
	}
}

public void InitState()
{
	gScoreSec = 0;
	gScoreIns = 0;
	gLoseTeam = NO_TEAM;
	SetTeamScore(TEAM_SEC, gScoreSec);
	SetTeamScore(TEAM_INS, gScoreIns);
	SetConVarInt(gCvarIgnoreWin, 1, false, false);
	SetConVarInt(gCvarIgnoreTimer, 1, false, false);
	if(gKickedTkerPlayersHandle == null){
		gKickedTkerPlayersHandle = CreateArray(ByteCountToCells(22)); 
	}else{
		ClearArray(gKickedTkerPlayersHandle);
	}
	for (int client = 1; client <= MaxClients; client++)
	{
		ClearClientTkerStates(client);
		if (IsClientInGame(client))
		{
			SetEntProp(client, Prop_Data, "m_takedamage", 2); //Disable god mode.
		}
	}
}

public void OnClientPostAdminCheck(int client)
{
	ClearClientTkerStates(client);
}

public void OnClientDisconnect_Post(int client)
{
	ClearClientTkerStates(client);
}

bool IsValidPlayer(int client)
{
	if(client > 0 && client <= MaxClients && IsClientInGame(client))
	{
		return true;
	}
	return false;
}

int IndexOfKickedPlayer(int client)
{
	if(!GetArraySize(gKickedTkerPlayersHandle)){
		return -1;
	}
	if(IsValidPlayer(client)){
		char authIdStr[22];
		char tempStr[22];
		GetClientAuthId(client, AuthId_Engine, authIdStr, sizeof(authIdStr));
		for(int i = 0; i < GetArraySize(gKickedTkerPlayersHandle); i++)
		{
			GetArrayString(gKickedTkerPlayersHandle,i,tempStr,sizeof(tempStr));
			if(!strcmp(authIdStr,tempStr,false))
			{
				return i;
			}
		}
	}
	return -1;
}

void PushKickedTkerPlayers(int client)
{
	if(IsValidPlayer(client)){
		char authIdStr[22];
		GetClientAuthId(client, AuthId_Engine, authIdStr, sizeof(authIdStr));
		PushArrayString(gKickedTkerPlayersHandle,authIdStr);
	}
}

public Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	InitState();
	return Plugin_Continue;
}

public Action Event_PlayerPickSquad(Event event, const char[] name, bool dontBroadcast)
{
	int userid = event.GetInt("userid");
	if(!IsPlayerAlive(GetClientOfUserId(userid)))
	{
		CreateTimer(gObserverRespawnTime, Timer_RespawnPlayer, userid, TIMER_FLAG_NO_MAPCHANGE);
	}
	return Plugin_Continue;
}
public Action Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	if(gLoseTeam != NO_TEAM)
	{
		return Plugin_Continue;
	}
	int attacker = event.GetInt("attacker");
	int attackerClient = GetClientOfUserId(attacker);
	int userid = event.GetInt("userid");
	int victimClient = GetClientOfUserId(userid);
	if(IsValidPlayer(victimClient) && IsValidPlayer(attackerClient))
	{
		if(gTkerId == userid)
		{
			//Delay tker's respawn
			gTkerId = 0;
			gIsTkerApologized[victimClient] = false;
			int time = RoundToCeil(GetClientTime(victimClient));
			int bigParam = time * 10000 + userid;
			CreateTimer(1.0, Timer_PunishTker, bigParam, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
			CreateTimer(1.0, Timer_ShowApologizeMenu, userid, TIMER_FLAG_NO_MAPCHANGE);

			return Plugin_Continue;
		}else{
			if(GetClientTeam(attackerClient) == GetClientTeam(victimClient) && userid != attacker && IsPlayerAlive(attackerClient))
			{
				//killed by teammate
				++gTkCount[attackerClient];
				PrintToChat(attackerClient,"Team-kill! (%d/%d)", gTkCount[attackerClient],gTkCountMax);
				if(gTkCount[attackerClient] >= gTkCountMax)
				{
					int index = IndexOfKickedPlayer(attackerClient);
					if(index >= 0)
					{
						//Ban the tker
						char tempStr[22];
						GetArrayString(gKickedTkerPlayersHandle,index,tempStr,sizeof(tempStr));
						BanIdentity(tempStr, 7*24*60, BANFLAG_AUTHID, "You killed too many teammates, you are banned for 7 days.");
					}else{
						//kick the tker
						PushKickedTkerPlayers(attackerClient);
						KickClient(attackerClient,"Kicked by server (Reach the team-kill limit)");
					}
				}else{
					gTkerId = attacker;
					//Slay the tker
					SlapPlayer(attackerClient,1000);
				}
			}else if(userid != attacker){
				//not suicide
				gScoreSec = GetTeamScore(TEAM_SEC);
				gScoreIns = GetTeamScore(TEAM_INS);
				PrintHintTextToAll("SEC(%d)  vs  INS(%d)", gScoreSec, gScoreIns);
				if(gScoreSec != gScoreIns)
				{
					if(gScoreSec >= gWinScore)
					{
						gLoseTeam = TEAM_INS;
					}else if(gScoreIns >= gWinScore){
						gLoseTeam = TEAM_SEC;
					}
				}
			}
		}
		if(gLoseTeam == NO_TEAM)
		{
			CreateTimer(gRespawnTime, Timer_RespawnPlayer, userid, TIMER_FLAG_NO_MAPCHANGE);
		}else{
			SetConVarInt(gCvarIgnoreWin, 0, false, false);
			SetConVarInt(gCvarIgnoreTimer, 0, false, false);
			for (int client = 1; client <= MaxClients; client++)
			{
				if (IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client)==gLoseTeam)
				{
					SlapPlayer(client,1000);
				}
			}
		}
	}
	return Plugin_Continue;
}
public Action Timer_RespawnPlayer(Handle timer,int userid)
{
	RespawnPlayer(userid);
}
public Action Timer_PunishTker(Handle timer,int bigParam)
{
	if(gLoseTeam != NO_TEAM)
	{
		return Plugin_Stop;
	}
	int time = bigParam / 10000;
	int userid = bigParam - (time * 10000);
	int client = GetClientOfUserId(userid);
	if(IsValidPlayer(client))
	{
		if(gIsTkerApologized[client])
		{
			return Plugin_Stop;
		}
		int leftTime = time + RoundToCeil(gTkPunishTime - GetClientTime(client));
		if(leftTime > 0)
		{
			PrintCenterText(client,"You killed a teammate! Before a respawn you must wait %d", leftTime);
		}else{
			RespawnPlayer(userid);
			return Plugin_Stop;
		}
	}
	return Plugin_Continue;
}
public Action Timer_DisableGodMode(Handle timer,int userid)
{
	DisableGodMode(userid);
}
public Action Timer_ShowApologizeMenu(Handle timer,int userid)
{
	int client = GetClientOfUserId(userid);

	Handle menu = CreateMenu(MenuHandler);
	SetMenuTitle(menu, "Apologize?");
	AddMenuItem(menu, "option1", "Yes");		
	SetMenuExitButton(menu, false);
	DisplayMenu(menu, client, 10);
}
public Action Timer_ApologizedRespawn(Handle timer,int bigParam)
{
	if(gLoseTeam != NO_TEAM)
	{
		return Plugin_Stop;
	}
	int time = bigParam / 10000;
	int userid = bigParam - (time * 10000);
	int client = GetClientOfUserId(userid);
	if(IsValidPlayer(client))
	{
		int leftTime = time + RoundToCeil(5.0 - GetClientTime(client));
		if(leftTime > 0)
		{
			PrintCenterText(client,"Apologized, respawn in %d", leftTime);
		}else{
			RespawnPlayer(userid);
			return Plugin_Stop;
		}
	}
	return Plugin_Continue;
}
public MenuHandler(Handle menu, MenuAction action, int client, int selectedItem)
{
	if (action == MenuAction_Select) 
	{
		switch (selectedItem)
		{
			case 0:
			{
				if(IsValidPlayer(client))
				{
					gIsTkerApologized[client] = true;
					int userid = GetClientUserId(client);
					int time = RoundToCeil(GetClientTime(client));
					int bigParam = time * 10000 + userid;
					FakeClientCommand(client, "say sorry");
					CreateTimer(1.0, Timer_ApologizedRespawn, bigParam, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
				}
			}
		}
	}		
}
