#if defined _level_keyvalues_included
	#endinput
#endif
#define _level_keyvalues_included

#include <more_adt>

static stock KeyValues KeyValueBuffer() {
	static KeyValues s_KVBuffer;
	if (!s_KVBuffer) {
		s_KVBuffer = new KeyValues("");
	}
	return s_KVBuffer;
}

/**
 * Wrapper for StringMultiMap that performs implicit string conversion.
 */
methodmap LevelEntityKeyValuesIterator < StringMultiMapIterator {
	public native int GetNum(int defaultValue = 0);
	public native void SetNum(int value);
	
	public native float GetFloat(float flDefaultValue = 0.0);
	public native void SetFloat(float flValue);
	
	public native void GetVector(float vec[3], const float defvalue[3])
	public native void SetVector(const float vec[3])
}

/**
 * Wrapper for StringMultiMap that performs implicit string conversion.
 */
methodmap LevelEntityKeyValues < StringMultiMap {
	public LevelEntityKeyValues() {
		return view_as<LevelEntityKeyValues>(new StringMultiMap());
	}
	
	public native int GetNum(const char[] key, int defaultValue = 0);
	public native void AddNum(const char[] key, int value);
	
	public native float GetFloat(const char[] key, float flDefaultValue = 0);
	public native void AddFloat(const char[] key, float value);
	
	public native void GetVector(const char[] key, float vec[3],
			const float defaultValue[3] = { 0.0, ... });
	public native void AddVector(const char[] key, const float vec[3]);
	
	public LevelEntityKeyValuesIterator GetKeyIterator(const char[] key) {
		return view_as<LevelEntityKeyValuesIterator>(
				view_as<StringMultiMap>(this).GetKeyIterator(key));
	}
}

/**
 * Called when a block of entity keys is finished parsing.
 * Changes to the StringMultiMap will be reflected in the level.
 * 
 * @return Plugin_Changed to copy back changed values, Plugin_Stop to remove the entity.
 */
forward Action LevelEntity_OnEntityKeysParsed(LevelEntityKeyValues entity);

/**
 * Called when the entity string in `OnLevelInit` has been fully parsed out.
 * Plugins may call LevelEntity_InsertEntityKeys here to insert new entities into the entity
 * string.
 */
forward void LevelEntity_OnAllEntitiesParsed();

/**
 * Adds a new entity entry.  All values should be strings.
 */
native void LevelEntity_InsertEntityKeys(LevelEntityKeyValues entity);

/**
 * Returns a copy of the KeyValues associated with the entity of a specified Hammer ID.
 * Any changes to the returned StringMultiMap handle will not be reflected in the level.
 */
native LevelEntityKeyValues LevelEntity_GetKeysByHammerID(int iHammerID);

/**
 * Returns a copy of the KeyValues associated with a given entity.
 */
stock LevelEntityKeyValues LevelEntity_GetKeysByEntity(int entref) {
	int entity = EntRefToEntIndex(entref);
	return LevelEntity_GetKeysByHammerID(GetEntProp(entity, Prop_Data, "m_iHammerID"));
}

/**
 * Parses an entity's output value (as formatted in the entity string).
 * Refer to https://developer.valvesoftware.com/wiki/AddOutput for the format.
 * 
 * @return True if the output string was successfully parsed, false if not.
 */
stock bool ParseEntityOutputString(const char[] output, char[] targetName, int targetNameLength,
		char[] inputName, int inputNameLength, char[] variantValue, int variantValueLength,
		float &delay, int &nFireCount) {
	int delimiter;
	char buffer[32];
	
	{
		// validate that we have something resembling an output string (four commas)
		int i, c, nDelim;
		while ((c = FindCharInString(output[i], ',')) != -1) {
			nDelim++;
			i += c + 1;
		}
		if (nDelim < 4) {
			return false;
		}
	}
	
	delimiter = SplitString(output, ",", targetName, targetNameLength);
	delimiter += SplitString(output[delimiter], ",", inputName, inputNameLength);
	delimiter += SplitString(output[delimiter], ",", variantValue, variantValueLength);
	
	delimiter += SplitString(output[delimiter], ",", buffer, sizeof(buffer));
	delay = StringToFloat(buffer);
	
	nFireCount = StringToInt(output[delimiter]);
	
	return true;
}


public SharedPlugin __pl_level_keyvalues = {
	name = "level-keyvalues",
	file = "level_keyvalues.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

public void __pl_level_keyvalues_SetNTVOptional() {
	#if !defined REQUIRE_PLUGIN
	MarkNativeAsOptional("LevelEntity_GetKeysByHammerID");
	#endif
}