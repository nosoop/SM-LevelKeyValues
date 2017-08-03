/**
 * [ANY?] Level KeyValues
 * 
 * Parses the level entity string (from SDKHooks' `OnLevelInit` forward) into a KeyValues
 * handle, indexed by Hammer ID.
 */
#pragma semicolon 1
#pragma dynamic 1048576
#include <sourcemod>

#include <sdkhooks>
#include <regex>

#pragma newdecls required

#define PLUGIN_VERSION "0.0.0"
public Plugin myinfo = {
	name = "Level KeyValues",
	author = "nosoop",
	description = "Parses the map entity string into a KeyValues structure.",
	version = PLUGIN_VERSION,
	url = "https://github.com/nosoop/SM-LevelKeyValues/"
}

KeyValues g_MapEntities;

public APLRes AskPluginLoad2(Handle self, bool late, char[] error, int err_max) {
	RegPluginLibrary("level-keyvalues");
	
	CreateNative("LevelEntity_GetKeysByHammerID", Native_GetKeysByHammerID);
	
	return APLRes_Success;
}

public Action OnLevelInit(const char[] mapName, char mapEntities[2097152]) {
	if (g_MapEntities) {
		delete g_MapEntities;
	}
	
	g_MapEntities = ParseEntityList(mapEntities);
	
	/**
	 * create a forward to allow manipulation of the KV?  create a cloned copy?
	 * could open up possibilities for dynamically filtering / adding new entities in ways that
	 * Stripper:Source doesn't support natively
	 */ 
	
	return Plugin_Continue;
}

public int Native_GetKeysByHammerID(Handle plugin, int argc) {
	// native KeyValues LevelEntity_GetKeysByHammerID(int iHammerID);
	int iHammerID = GetNativeCell(1);
	
	char hammerID[64];
	IntToString(iHammerID, hammerID, sizeof(hammerID));
	
	if (g_MapEntities && g_MapEntities.JumpToKey(hammerID, false)) {
		// create and transfer ownership of KeyValues
		KeyValues kv = new KeyValues(hammerID);
		KeyValues retval = view_as<KeyValues>(CloneHandle(kv, plugin));
		
		kv.Import(g_MapEntities);
		g_MapEntities.GoBack();
		
		delete kv;
		
		return view_as<int>(retval);
	}
	return 0;
}

/**
 * Parses the level entity string into a KeyValues struct.
 * The KeyValues struct organizes keys using the `hammerid` as the section names.
 */
static KeyValues ParseEntityList(const char mapEntities[2097152]) {
	static Regex s_KeyValueLine;
	
	if (!s_KeyValueLine) {
		// Pattern copied from alliedmodders/stripper-source/master/parser.cpp
		s_KeyValueLine = new Regex("\"([^\"]+)\"\\s+\"([^\"]+)\"");
	}
	
	KeyValues mapKeyValues = new KeyValues("map_entities");
	
	int nKeys;
	
	char key[256], value[256];
	
	int i, n;
	char lineBuffer[4096];
	while ((n = SplitString(mapEntities[i], "\n", lineBuffer, sizeof(lineBuffer))) != -1) {
		switch(lineBuffer[0]) {
			case '{': {
				char sectionValue[128];
				Format(sectionValue, sizeof(sectionValue), "__parsed_unknown_%d", nKeys);
				
				mapKeyValues.JumpToKey(sectionValue, true);
				nKeys++;
			}
			case '}': {
				mapKeyValues.GoBack();
				
				// next open bracket starts on same line
				if (lineBuffer[1] == '{') {
					char sectionValue[128];
					Format(sectionValue, sizeof(sectionValue), "__parsed_unknown_%d", nKeys);
					
					mapKeyValues.JumpToKey(sectionValue, true);
					nKeys++;
				}
			}
			default: {
				if (s_KeyValueLine.Match(lineBuffer)) {
					s_KeyValueLine.GetSubString(1, key, sizeof(key));
					s_KeyValueLine.GetSubString(2, value, sizeof(value));
					
					KeyValues_AddString(mapKeyValues, key, value);
					
					// change section name to hammerid for quick lookup (`m_iHammerID` dataprop)
					if (StrEqual(key, "hammerid")) {
						mapKeyValues.SetSectionName(value);
					}
				}
			}
		}
		i += n;
	}
	mapKeyValues.GoBack();
	mapKeyValues.SetNum("num_entities", nKeys);
	
	return mapKeyValues;
}

/**
 * Adds a new key/value pair to the KeyValues structure in a way that allows for duplicate key
 * names.
 */
static void KeyValues_AddString(KeyValues kv, const char[] key, const char[] value) {
	static int s_nTempKey;
	
	char tempKey[64];
	Format(tempKey, sizeof(tempKey), "__levelkv_temp_buffer_%d", s_nTempKey++);
	
	kv.SetString(tempKey, value);
	
	kv.JumpToKey(tempKey);
	kv.GotoFirstSubKey(false);
	kv.SetSectionName(key);
	kv.GotoNextKey();
	
	kv.GoBack();
}
