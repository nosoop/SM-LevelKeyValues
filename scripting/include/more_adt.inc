#if defined __more_adt_ext
	#endinput
#endif

/**
 * An iterator for the StringMultiMap.
 * Call its Next() function before performing any retrievals to ensure that it is valid.
 */
methodmap StringMultiMapIterator < Handle {
	public native bool Next();
	public native void GetKey(char[] name, int maxlen);
	
	/** 
	 * Returns the string at the current iterator position.
	 */
	public native bool GetString(char[] value, int max_size, int& size = 0);
	public native void SetString(const char[] value);
	
	public native bool GetValue(any &value);
	public native void SetValue(any value);
	
	public native bool GetArray(any[] array, int max_size, int& size = 0);
	public native void SetArray(const any[] array, int num_items);
	
	/**
	 * Marks the element at the current iterator position as removed.
	 * The entry will be removed on the next invocation of Next().
	 */
	public native void Remove();
}

/**
 * Creates a multimap.  A multimap is a container that can map keys to arbitrary values.
 * 
 * There can be multiple entries in a multimap for a given key; only the first inerted entry
 * will be accessible through the Get*() methods.  To retrieve all the entries for a given key,
 * use the GetKeyIterator() method to get an iterator over the specified key.
 */
methodmap StringMultiMap < Handle {
	public native StringMultiMap();
	
	/**
	 * Removes all elements with the key equivalent to `key`.
	 */
	public native void Remove(const char[] key);
	
	/**
	 * Adds a new value with the specified `key`.
	 */
	public native void AddValue(const char[] key, any value);
	
	/**
	 * Returns true iff the first entry associated with a key is a cell value, populating the
	 * passed-in by-ref `value` argument.
	 */
	public native bool GetValue(const char[] key, any &value);
	
	/**
	 * Adds a new string value with the specified key.
	 */
	public native void AddString(const char[] key, const char[] value);
	
	/**
	 * Returns true iff the first entry associated with a key is a string value, filling the
	 * passed-in `value` buffer.
	 */
	public native bool GetString(const char[] key, char[] value, int max_size, int& size = 0);
	
	public native void AddArray(const char[] key, const any[] array, int num_items);
	public native void GetArray(const char[] key, any[] array, int max_size, int& size = 0);
	
	/**
	 * Returns an interator over all keys.  Will still return a valid StringMultiMapIterator
	 * handle even if the StringMultiMap is empty.
	 */
	public native StringMultiMapIterator GetIterator();
	
	/**
	 * Returns an iterator for elements matching a specific key.
	 * (Wrapper for std::multimap::equal_range.)
	 */
	public native StringMultiMapIterator GetKeyIterator(const char[] key);
}

public Extension __ext_madt = {
	name = "More ADTs",
	file = "madt.ext",
#if defined AUTOLOAD_EXTENSIONS
	autoload = 1,
#else
	autoload = 0,
#endif
#if defined REQUIRE_EXTENSIONS
	required = 1,
#else
	required = 0,
#endif
};

#if !defined REQUIRE_EXTENSIONS
public void __ext_madt_SetNTVOptional() {
}
#endif