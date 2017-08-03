#if defined _level_keyvalues_included
	#endinput
#endif
#define _level_keyvalues_included

/**
 * Returns a copy of the KeyValues associated with the entity of a specified Hammer ID.
 * The KeyValues handle returned by the native is read-only; any changes made do not propagate
 * up to the shared plugin.
 */
native KeyValues LevelEntity_GetKeysByHammerID(int iHammerID);

/**
 * Returns a copy of the KeyValues associated with a given entity.
 */
stock KeyValues LevelEntity_GetKeysByEntity(int entref) {
	int entity = EntRefToEntIndex(entref);
	return LevelEntity_GetKeysByHammerID(GetEntProp(entity, Prop_Data, "m_iHammerID"));
}

/**
 * Parses an entity's output value (as formatted in the entity string).
 * 
 * Refer to https://developer.valvesoftware.com/wiki/AddOutput for the format.
 */
stock bool ParseEntityOutputString(const char[] output, char[] targetName, int targetNameLength,
		char[] inputName, int inputNameLength, char[] variantValue, int variantValueLength,
		float &delay, int &nFireCount) {
	int delimiter;
	char buffer[32];
	
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