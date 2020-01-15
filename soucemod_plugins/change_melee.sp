#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

static const int g_FakeMeleeWeapons[4] = {11,12,13,14};
static const int g_MeleeWeapons[4] = {1,2,3,4};
int g_ClientOwnFakeMeleeWeapon[MAXPLAYERS+1];

public Plugin myinfo = 
{
	name = "change_melee",
	author = "slimfish",
	description = "change melee",
	version = "1.0",
	url = "i.slimfish.net"
}

public void OnPluginStart()
{
	AddCommandListener(Event_InventoryBuyGear,"inventory_buy_gear");
    AddCommandListener(Event_InventorySellGear,"inventory_sell_gear");
}

public Action Event_InventoryBuyGear(int client, const char[] command, int argc)
{
    if(client > 0 && client <= MaxClients && IsClientInGame(client))
    {
        int param = GetInventoryParam();
        int meleeIndex = -1;

        for(int i = 0; i < sizeof(g_FakeMeleeWeapons); i++)
        {
            if(param == g_FakeMeleeWeapons[i])
            {
                meleeIndex = i;
                g_ClientOwnFakeMeleeWeapon[client] = param;
                break;
            }
        }
        if(meleeIndex >= 0)
        {
            FakeClientCommandEx(client,"inventory_buy_weapon %d",g_MeleeWeapons[meleeIndex]);
        }
    }
    return Plugin_Continue;
}

public Action Event_InventorySellGear(int client, const char[] command, int argc)
{
	if(client > 0 && client <= MaxClients && IsClientInGame(client))
    {
        int param = GetInventoryParam();
        int meleeIndex = -1;

        for(int i = 0; i < sizeof(g_FakeMeleeWeapons); i++)
        {
            if(param == g_FakeMeleeWeapons[i])
            {
                meleeIndex = i;
                g_ClientOwnFakeMeleeWeapon[client] = 0;
                break;
            }
        }
        if(meleeIndex >= 0)
        {
            FakeClientCommandEx(client,"inventory_sell_weapon %d",g_MeleeWeapons[meleeIndex]);
        }
    }
    return Plugin_Continue;
}

public Action OnClientCommand(int client, int args)
{
    if(client > 0 && client <= MaxClients && IsClientInGame(client))
    {
        char cmdStr[MAX_NAME_LENGTH];
        GetCmdArg(0, cmdStr, sizeof(cmdStr));
        if(StrEqual(cmdStr,"inventory_buy_weapon"))
        {
            int param = GetInventoryParam();
            for(int i = 0; i < sizeof(g_MeleeWeapons); i++)
            {
                if(param == g_MeleeWeapons[i])
                {
                    //如果玩家拥有的假刀具与真刀具没有对应关系，则认为是作弊购买
                    if(g_ClientOwnFakeMeleeWeapon[client] != g_FakeMeleeWeapons[i])
                    {
                        return Plugin_Handled;
                    }
                    break;
                }
            }
        }
    }
    return Plugin_Continue;
}

public int GetInventoryParam()
{
    char argStr[4];
    GetCmdArg(1, argStr, sizeof(argStr));
    int arg = StringToInt(argStr);
    argStr[0] = '\0';
    if(arg > 0)
    {
        return arg;
    }
    return 0;
}