# styx-godot

## Dependencies

```
git clone git@github.com:kevinw/GodotVision.git
git clone git@github.com:multijam/SwiftGodot.git
git clone git@github.com:multijam/SwiftGodotKit.git
```

* Download Godot 4.3 version of `libgodot.xcframework.zip` (link: https://github.com/multijam/SwiftGodot/releases/download/4.3.0/libgodot.xcframework.zip), extract `libgodot.xcframework` and place into `SwiftGodot` root directory from git repository (this prevents a later error during import that local binary targets `libgodot_tests` and `binary_libgodot` at the `SwiftGodot/libgodot.xcframework` location "does not contain a binary artifact.")
