> [!NOTE]  
> This project has been deprecated and archived; it no longer functions in SourceMod 1.11
> and newer.
> 
> However, it lives on in the form of the [entity lump natives][] I've introduced in those
> newer versions.  While there are differences that prevent existing plugins from being
> directly ported to the new built-in system, I believe the new system is much more friendly
> to work with.

[entity lump natives]: https://wiki.alliedmods.net/Entity_Lumps_(SourceMod_Scripting)

# Level KeyValues
A helper plugin that transforms the level's entity string into a `StringMultiMap` handle.

## Dependencies

* The [More ADTs extension][madt] provides the `StringMultiMap` handle type, providing proper
support for one-to-many mappings without an additional handle for each unique key.

[madt]: https://github.com/nosoop/SMExt-MoreADTs/releases

## Usage

Think of it as a more flexible, barebones version of [Stripper:Source].

You don't get the nice configuration files for fixed filterings, but you do get the following:

```
forward Action LevelEntity_OnEntityKeysParsed(LevelEntityKeyValues entity);
```

Plugins listening to the forward can add / remove keys, or return `Plugin_Stop` to filter the
entity out entirely.

```
forward void LevelEntity_OnAllEntitiesParsed();
native void LevelEntity_InsertEntityKeys(LevelEntityKeyValues entity);
```

Plugins can instantiate their own instances of `LevelEntityKeyValues` and call
`LevelEntity_InsertEntityKeys` during this forward to add them to the level.

[Stripper:Source]: http://www.bailopan.net/stripper/
