# Contains some handy functions for generating Putter file manifests.

{ lib }:

let

  inherit (lib)
    hasPrefix
    filter
    ;

in
{
  # Converts a Home Manager style list of file specifications into a Putter
  # configuration.
  #
  # Note, the interface of this function is not considered stable, it may change
  # as the needs of Home Manager change.
  mkPutterManifest =
    {
      putterStatePath,
      sourceBaseDirectory,
      targetBaseDirectory,
      fileEntries,
    }:
    let
      # Create a Putter entry for the given file.
      mkEntry = f: {
        collision.resolution = if f.force then "force" else "abort";
        action.type = if f.recursive then "symlink_recursive" else "symlink";
        source = "${sourceBaseDirectory}/${f.target}";
        target = (if hasPrefix "/" f.target then "" else "${targetBaseDirectory}/") + f.target;
      };

      putterJson = {
        version = "1";
        state = putterStatePath;
        files = map mkEntry (filter (f: f.enable) fileEntries);
      };

      putterJsonText = builtins.toJSON putterJson;
    in
    putterJsonText;
}
