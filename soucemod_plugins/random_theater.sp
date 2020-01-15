#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

public Plugin myinfo = 
{
	name = "random_theater",
	author = "slimfish",
	description = "load random theater.",
	version = "1.0",
	url = "i.slimfish.net"
}

public void OnPluginStart()
{
    UpdateTheater();
}

public void OnMapEnd()
{
    //此时更改只会在下次关卡应用
    UpdateTheater();
}

public void UpdateTheater()
{
    ConVar cvarTheaterOverride = FindConVar("mp_theater_override");
    int randomInt = GetRandomInt(1,2);
    if(randomInt == 1)
    {
        SetConVarString(cvarTheaterOverride,"fishpond_pve_sec",false,false);
    }else{
        SetConVarString(cvarTheaterOverride,"fishpond_pve_ins",false,false);
    }
}