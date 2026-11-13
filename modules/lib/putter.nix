# Contains some handy functions for generating Putter file manifests.

{ lib }:

let

  inherit (lib)
    filter
    hasPrefix
    optionalAttrs
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
      mkEntry =
        f:
        {
          source = "${sourceBaseDirectory}/${f.target}";
          # source = "${f.source}";
          target = (if hasPrefix "/" f.target then "" else "${targetBaseDirectory}/") + f.target;
        }
        // optionalAttrs f.force {
          collision.resolution = "force";
        }
        // optionalAttrs f.recursive {
          action.type = "recursive_symlink";
        };

      putterJson = {
        version = "1";
        state = putterStatePath;
        files = map mkEntry (filter (f: f.enable) fileEntries);
      };

      putterJsonText = builtins.toJSON putterJson;
    in
    putterJsonText;

  # Create a putter state file to allow compatibility between legacy and putter
  # managed files.
  #
  # Note, the interface of this function is not considered stable, it may change
  # as the needs of Home Manager change.
  mkPutterCompatState =
    {
      sourceBaseDirectory,
      targetBaseDirectory,
      fileEntries,
    }:
    let
      mkEntry = f: {
        name = (if hasPrefix "/" f.target then "" else "${targetBaseDirectory}/") + f.target;
        value = {
          source = "${sourceBaseDirectory}/${f.target}";
          modified = {
            secs_since_epoch = 0;
            nanos_since_epoch = 0;
          };
        };
      };

      stateJsonText = builtins.toJSON {
        version = "1";
        files = lib.listToAttrs (map mkEntry (filter (f: f.enable) fileEntries));
      };
    in
    stateJsonText;
}
