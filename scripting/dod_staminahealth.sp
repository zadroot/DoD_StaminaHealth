/**
* DoD:S Stamina Health by Root
*
* Description:
*   Sets player's stamina reflect to multiplied health.
*
* Version 1.0
* Changelog & more info at http://goo.gl/4nKhJ
*/

// ====[ INCLUDES ]==========================================================
#include <sdkhooks>
#include <sdktools_sound>

// ====[ CONSTANTS ]=========================================================
#define PLUGIN_NAME    "DoD:S Stamina Health"
#define PLUGIN_VERSION "1.0"

// ====[ PLUGIN ]============================================================
new	Handle:SH_Enabled = INVALID_HANDLE, Handle:SH_Multipler = INVALID_HANDLE;
public Plugin:myinfo  =
{
	name        = PLUGIN_NAME,
	author      = "Root",
	description = "Sets player's stamina reflect to a multiplied health",
	version     = PLUGIN_VERSION,
	url         = "http://dodsplugins.com/"
}


/* OnPluginStart()
 *
 * When the plugin starts up.
 * -------------------------------------------------------------------------- */
public OnPluginStart()
{
	// Create plugin's console variables
	CreateConVar("dod_staminahealth_version", PLUGIN_VERSION, PLUGIN_NAME, FCVAR_NOTIFY|FCVAR_DONTRECORD);
	SH_Enabled   = CreateConVar("dod_staminahealth_enabled",   "1",   "Whether or not set stamina reflect to multiplied health",   FCVAR_PLUGIN, true, 0.0, true, 1.0);
	SH_Multipler = CreateConVar("dod_staminahealth_multipler", "1.0", "Determines a multipler for player health to set a stamina", FCVAR_PLUGIN, true, 1.0);

	// Hook changes only for main variable
	HookConVarChange(SH_Enabled, OnPluginToggle);

	// Simulates late load for a plugin
	OnPluginToggle(SH_Enabled, "0", "1");
}

/* OnPluginToggle()
 *
 * Called when plugin is enabled or disabled by ConVar.
 * -------------------------------------------------------------------------- */
public OnPluginToggle(Handle:convar, const String:oldValue[], const String:newValue[])
{
	// Loop through all valid clients
	for (new i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i)) continue;

		// Get the new changed value
		switch (StringToInt(newValue))
		{
			// If plugin is disabled - unhook PostThink callback, because its a bit expensive for a server
			case false:
			{
				SDKUnhook(i, SDKHook_OnTakeDamagePost, OnTakeDamagePost);
				SDKUnhook(i, SDKHook_PostThinkPost,    PostThinkPost);
			}
			case true:
			{
				// Otherwise hook callback after player is taking a damage and PostThinkPost
				SDKHook(i, SDKHook_OnTakeDamagePost, OnTakeDamagePost);
				SDKHook(i, SDKHook_PostThinkPost,    PostThinkPost);
			}
		}
	}
}

/* OnClientPutInServer()
 *
 * Called when a client is entering the game.
 * -------------------------------------------------------------------------- */
public OnClientPutInServer(client)
{
	// Hook all needed callbacks for a client
	SDKHook(client, SDKHook_OnTakeDamagePost, OnTakeDamagePost);
	SDKHook(client, SDKHook_PostThinkPost,    PostThinkPost);
}

/* OnTakeDamagePost()
 *
 * Called when a player takes damage.
 * -------------------------------------------------------------------------- */
public OnTakeDamagePost(victim, attacker, inflictor, Float:damage, damagetype)
{
	// Make sure victim is okay
	if (1 <= victim <= MaxClients)
	{
		// If player is having less than 34 health (it's when stamina is getting red)
		if (GetClientHealth(victim) * GetConVarInt(SH_Multipler) < 34)
		{
			// Respectively stop breath sound
			StopSound(victim, SNDCHAN_AUTO, "player/sprint.wav");
		}
	}
}

/* PostThinkPost()
 *
 * Post hook, which is called on every frame.
 * -------------------------------------------------------------------------- */
public PostThinkPost(client)
{
	// Make sure player is not sprinting now
	if (!GetEntProp(client, Prop_Send, "m_bIsSprinting", true))
	{
		// Get the multipler for health, real amout of health (in float) and a stamina percent
		new Float:multipler = GetConVarFloat(SH_Multipler);
		new Float:health    = float(GetClientHealth(client));

		// If stamina is more than multiplied health
		if (GetEntPropFloat(client, Prop_Send, "m_flStamina") > FloatMul(health, multipler))
		{
			// Correct player stamina
			SetEntPropFloat(client, Prop_Send, "m_flStamina", FloatMul(health, multipler));
		}
	}
}