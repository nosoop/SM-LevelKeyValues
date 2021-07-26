/**
 * [ANY?] Level KeyValues
 * 
 * Parses the level entity string (from SDKHooks' `OnLevelInit` forward) into a KeyValues
 * handle, indexed by Hammer ID.
 */
#pragma semicolon 1
#include <sourcemod>

#include <sdkhooks>
#include <regex>

#include <more_adt>
#include <entitylump>

#include "level_keyvalues/map_string_natives.sp"

#pragma newdecls required

#define PLUGIN_VERSION "0.3.4"
public Plugin myinfo = {
	name = "Level KeyValues",
	author = "nosoop",
	description = "Parses the map entity string into a KeyValues-like structure.",
	version = PLUGIN_VERSION,
	url = "https://github.com/nosoop/SM-LevelKeyValues/"
}

ArrayList g_MapEntities;
bool g_bMutableList;

Handle g_OnEntityKeysParsed, g_OnAllEntitiesParsed;

public APLRes AskPluginLoad2(Handle self, bool late, char[] error, int err_max) {
	RegPluginLibrary("level-keyvalues");
	
	CreateNative("LevelEntity_GetKeysByHammerID", Native_GetKeysByHammerID);
	CreateNative("LevelEntity_InsertEntityKeys", Native_InsertEntity);
	
	CreateNative("LevelEntityKeyValues.GetNum", Native_MapGetNum);
	CreateNative("LevelEntityKeyValues.AddNum", Native_MapAddNum);
	
	CreateNative("LevelEntityKeyValues.GetFloat", Native_MapGetFloat);
	CreateNative("LevelEntityKeyValues.AddFloat", Native_MapAddFloat);
	
	CreateNative("LevelEntityKeyValues.GetVector", Native_MapGetVector);
	CreateNative("LevelEntityKeyValues.AddVector", Native_MapAddVector);
	
	CreateNative("LevelEntityKeyValuesIterator.GetNum", Native_MapIterGetNum);
	CreateNative("LevelEntityKeyValuesIterator.SetNum", Native_MapIterSetNum);
	
	CreateNative("LevelEntityKeyValuesIterator.GetFloat", Native_MapIterGetFloat);
	CreateNative("LevelEntityKeyValuesIterator.SetFloat", Native_MapIterSetFloat);
	
	CreateNative("LevelEntityKeyValuesIterator.GetVector", Native_MapIterGetVector);
	CreateNative("LevelEntityKeyValuesIterator.SetVector", Native_MapIterSetVector);
	
	CreateNative("LevelEntityList.Get", Native_LevelListGet);
	CreateNative("LevelEntityList.Push", Native_InsertEntity);
	CreateNative("LevelEntityList.Erase", Native_LevelListErase);
	CreateNative("LevelEntityList.Length", Native_LevelListGetLength);
	
	return APLRes_Success;
}

public void OnPluginStart() {
	g_OnEntityKeysParsed = CreateGlobalForward("LevelEntity_OnEntityKeysParsed", ET_Hook,
			Param_Cell);
	g_OnAllEntitiesParsed = CreateGlobalForward("LevelEntity_OnAllEntitiesParsed", ET_Ignore);
}

public void OnMapEntitiesParsed() {
	if (g_MapEntities) {
		while (g_MapEntities.Length) {
			StringMultiMap handle = g_MapEntities.Get(0);
			delete handle;
			g_MapEntities.Erase(0);
		}
		delete g_MapEntities;
	}
	
	g_MapEntities = ParseEntityList();
	
	g_bMutableList = true;
	Call_StartForward(g_OnAllEntitiesParsed);
	Call_Finish();
	g_bMutableList = false;
	
	WriteEntityList(g_MapEntities);
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

public int Native_LevelListGet(Handle plugin, int argc) {
	return view_as<int>(CloneHandle(g_MapEntities.Get(GetNativeCell(1)), plugin));
}

public int Native_LevelListErase(Handle plugin, int argc) {
	if (!g_bMutableList) {
		ThrowNativeError(1, "Can't remove entities from list during non-mutable state.");
	}
	StringMultiMap entity = g_MapEntities.Get(GetNativeCell(1));
	delete entity;
	
	g_MapEntities.Erase(GetNativeCell(1));
	return 0;
}

public int Native_InsertEntity(Handle plugin, int argc) {
	if (!g_bMutableList) {
		ThrowNativeError(1, "Can't push new entity into list during non-mutable state.");
	}
	StringMultiMap entity = GetNativeCell(1);
	return g_MapEntities.Push(CloneStringMultiMap(entity));
}

public int Native_LevelListGetLength(Handle plugin, int argc) {
	return g_MapEntities.Length;
}

StringMultiMap CloneStringMultiMap(StringMultiMap source) {
	char key[256], value[256];
	StringMultiMapIterator iter = source.GetIterator();
	
	StringMultiMap output = new StringMultiMap();
	while (iter.Next()) {
		iter.GetKey(key, sizeof(key));
		if (iter.GetString(value, sizeof(value))) {
			output.AddString(key, value);
		}
	}
	return output;
}

/**
 * Translates the EntityLump entries into an ArrayList of StringMultiMap handles.
 */
static ArrayList ParseEntityList() {
	ArrayList mapEntityList = new ArrayList();
	
	char key[256], value[256];
	
	for (int i, n = EntityLump.Length(); i < n; i++) {
		EntityLumpEntry entry = EntityLump.Get(i);
		StringMultiMap mm = new StringMultiMap();
		
		for (int k, kn = entry.Length; k < kn; k++) {
			entry.Get(k, key, sizeof(key), value, sizeof(value));
			mm.AddString(key, value);
		}
		
		delete entry;
		
		if (ForwardOnEntityKeysParsed(mm) != Plugin_Stop) {
			mapEntityList.Push(mm);
		} else {
			delete mm;
			// filtered entities will not propagate back to the EntityLump after it's cleared
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
 * Writes the entity list back out.
 */
void WriteEntityList(ArrayList entityList) {
	// oh no
	while (EntityLump.Length()) {
		EntityLump.Erase(0);
	}
	
	for (int i, n = entityList.Length; i < n; i++) {
		EntityLumpEntry newEntry = EntityLump.Get(EntityLump.Append());
		
		StringMultiMap mm = entityList.Get(i);
		StringMultiMapIterator keyiter = mm.GetIterator();
		while (keyiter.Next()) {
			char key[64], value[1024];
			keyiter.GetKey(key, sizeof(key));
			keyiter.GetString(value, sizeof(value));
			
			newEntry.Append(key, value);
		}
		
		delete newEntry;
	}
}
