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
 * A KeyValues-backed handle that returns and iterates over keys that match the given output
 * name, parsing the output value into its components while being iterated.
 */
methodmap LevelEntityOutputIterator < KeyValues {
	/**
	 * Creates an output iterator for a given Hammer ID.
	 */
	public LevelEntityOutputIterator(int hammerID, const char[] output) {
		KeyValues outputs = LevelEntity_GetKeysByHammerID(hammerID);
		if (outputs) {
			char keyBuffer[128], valueBuffer[128];
			outputs.GotoFirstSubKey(false);
			bool bNext;
			do {
				outputs.GetSectionName(keyBuffer, sizeof(keyBuffer));
				outputs.GetString(NULL_STRING, valueBuffer, sizeof(valueBuffer));
				
				if (!StrEqual(keyBuffer, output)) {
					bNext = outputs.DeleteThis() != -1;
				} else {
					bNext = outputs.GotoNextKey(false);
				}
			} while (bNext);
			outputs.GotoFirstSubKey(false);
		}
		return view_as<LevelEntityOutputIterator>(outputs);
	}
	
	/**
	 * Returns an output iterator for a given entity (reference), looking it up by its Hammer
	 * ID.
	 */
	public static LevelEntityOutputIterator FromEntity(int entref, const char[] output) {
		int entity = EntRefToEntIndex(entref);
		return new LevelEntityOutputIterator(GetEntProp(entity, Prop_Data, "m_iHammerID"),
				output);
	}
	
	/**
	 * Parses the current output string, storing the values by reference and advancing to the
	 * next key.
	 */
	public bool Next(char[] targetName, int targetNameLength,
			char[] inputName, int inputNameLength, char[] variantValue, int variantValueLength,
			float &delay, int &nFireCount) {
		char outputString[512];
		this.GetString(NULL_STRING, outputString, sizeof(outputString));
		
		// this.GoBack() is a disgusting hack just to make sure it returns true on the last item
		return ParseEntityOutputString(outputString, targetName, targetNameLength, inputName,
				inputNameLength, variantValue, variantValueLength, delay, nFireCount)
				&& (this.GotoNextKey(false) || this.GoBack());
	}
}

/**
 * Returns a copy of the KeyValues associated with a given entity.
 */
stock KeyValues LevelEntity_GetKeysByEntity(int entref) {
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