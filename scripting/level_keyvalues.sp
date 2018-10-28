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

#include <more_adt>

#pragma newdecls required

#define PLUGIN_VERSION "0.1.0"
public Plugin myinfo = {
	name = "Level KeyValues",
	author = "nosoop",
	description = "Parses the map entity string into a KeyValues structure.",
	version = PLUGIN_VERSION,
	url = "https://github.com/nosoop/SM-LevelKeyValues/"
}

ArrayList g_MapEntities;

Handle g_OnEntityKeysParsed, g_OnAllEntitiesParsed;

public APLRes AskPluginLoad2(Handle self, bool late, char[] error, int err_max) {
	RegPluginLibrary("level-keyvalues");
	
	CreateNative("LevelEntity_GetKeysByHammerID", Native_GetKeysByHammerID);
	CreateNative("LevelEntity_InsertEntityKeys", Native_InsertEntity);
	
	return APLRes_Success;
}

public void OnPluginStart() {
	g_OnEntityKeysParsed = CreateGlobalForward("LevelEntity_OnEntityKeysParsed", ET_Hook,
			Param_Cell);
	g_OnAllEntitiesParsed = CreateGlobalForward("LevelEntity_OnAllEntitiesParsed", ET_Ignore);
}

public Action OnLevelInit(const char[] mapName, char mapEntities[2097152]) {
	if (g_MapEntities) {
		while (g_MapEntities.Length) {
			StringMultiMap handle = g_MapEntities.Get(0);
			delete handle;
			g_MapEntities.Erase(0);
		}
		delete g_MapEntities;
	}
	
	g_MapEntities = ParseEntityList(mapEntities);
	
	Call_StartForward(g_OnAllEntitiesParsed);
	Call_Finish();
	
	mapEntities = "";
	WriteEntityList(g_MapEntities, mapEntities, sizeof(mapEntities));
	
	return Plugin_Continue;
}

public int Native_GetKeysByHammerID(Handle plugin, int argc) {
	// native KeyValues LevelEntity_GetKeysByHammerID(int iHammerID);
	int iHammerID = GetNativeCell(1);
	for (int i = 0; i < g_MapEntities.Length; i++) {
		StringMultiMap entityKeys = g_MapEntities.Get(i);
		char hid[16];
		if (entityKeys.GetString("hammerid", hid, sizeof(hid))) {
			if (StringToInt(hid) == iHammerID) {
				return view_as<int>(CloneHandle(entityKeys, plugin));
			}
		}
	}
	
	return 0;
}

public int Native_InsertEntity(Handle plugin, int argc) {
	StringMultiMap entity = GetNativeCell(1);
	g_MapEntities.Push(entity);
	return;
}

/**
 * Parses the level entity string into an ArrayList of StringMultiMap handles.
 */
static ArrayList ParseEntityList(const char mapEntities[2097152]) {
	static Regex s_KeyValueLine;
	
	if (!s_KeyValueLine) {
		// Pattern copied from alliedmodders/stripper-source/master/parser.cpp
		s_KeyValueLine = new Regex("\"([^\"]+)\"\\s+\"([^\"]+)\"");
	}
	
	ArrayList mapEntityList = new ArrayList();
	
	int nKeys;
	
	char key[256], value[256];
	
	StringMultiMap currentEntityMap;
	
	int i, n;
	char lineBuffer[4096];
	while ((n = SplitString(mapEntities[i], "\n", lineBuffer, sizeof(lineBuffer))) != -1) {
		switch(lineBuffer[0]) {
			case '{': {
				currentEntityMap = new StringMultiMap();
				nKeys++;
			}
			case '}': {
				if (ForwardOnEntityKeysParsed(currentEntityMap) != Plugin_Stop) {
					mapEntityList.Push(currentEntityMap);
				} else {
					delete currentEntityMap;
				}
				
				// next open bracket starts on same line
				if (lineBuffer[1] == '{') {
					currentEntityMap = new StringMultiMap();
					nKeys++;
				}
			}
			default: {
				if (s_KeyValueLine.Match(lineBuffer)) {
					s_KeyValueLine.GetSubString(1, key, sizeof(key));
					s_KeyValueLine.GetSubString(2, value, sizeof(value));
					
					currentEntityMap.AddString(key, value);
				}
			}
		}
		i += n;
	}
	
	if (currentEntityMap) {
		if (ForwardOnEntityKeysParsed(currentEntityMap) != Plugin_Stop) {
			mapEntityList.Push(currentEntityMap);
		} else {
			delete currentEntityMap;
		}
	}
	
	return mapEntityList;
}

Action ForwardOnEntityKeysParsed(StringMultiMap entity) {
	Action result;
	Call_StartForward(g_OnEntityKeysParsed);
	Call_PushCell(entity);
	Call_Finish(result);
	
	return result;
}

/**
 * Writes the entity list back out in level string format.
 */
void WriteEntityList(ArrayList entityList, char[] buffer, int maxlen) {
	for (int i = 0; i < entityList.Length; i++) {
		StrCat(buffer, maxlen, "{\n");
		
		StringMultiMapIterator keyiter = view_as<StringMultiMap>(entityList.Get(i)).GetIterator();
		while (keyiter.Next()) {
			char key[64], value[256];
			keyiter.GetKey(key, sizeof(key));
			keyiter.GetString(value, sizeof(value));
			
			char lineBuffer[512];
			Format(lineBuffer, sizeof(lineBuffer), "\"%s\" \"%s\"\n", key, value);
			StrCat(buffer, maxlen, lineBuffer);
		}
		delete keyiter;
		
		StrCat(buffer, maxlen, "}\n");
	}
}

/**
 * Converts a string to lower case.
 */
stock void StrToLower(char[] buffer) {
	int c;
	do {
		buffer[c] = CharToLower(buffer[c]);
	} while (buffer[++c]);
}
