# Contains some handy functions for generating Putter file manifests.

{ lib }:

let

  inherit (lib)
    concatMap
    concatLists
    mapAttrsToList
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
      # Convert a directory to a Putter configuration. Basically, this will
      # create a file entry for each file in the directory. Any sub-directories
      # will be handled recursively.
      mkDirEntry =
        f:
        concatLists (
          mapAttrsToList (
            n: v:
            let
              f' = f // {
                source = "${f.source}/${n}";
                target = "${f.target}/${n}";
              };
            in
            mkEntriesForType f' v
          ) (builtins.readDir f.source)
        );

      mkEntriesForType =
        f: t:
        if t == "regular" || t == "symlink" then
          mkFileEntry f
        else if t == "directory" then
          mkDirEntry f
        else
          throw "unexpected file type ${t}";

      # Create a file entry for the given file.
      mkFileEntry = f: [
        {
          collision.resolution = if f.force then "force" else "abort";
          action.type = "symlink";
          source = "${sourceBaseDirectory}/${f.target}";
          target = (if hasPrefix "/" f.target then "" else "${targetBaseDirectory}/") + f.target;
        }
      ];

      # Given a Home Manager file entry, produce a list of Putter entries. For
      # recursive HM file entries, we recursively traverse the source directory
      # and generate a Putter entry for each file we encounter.
      mkEntries = f: if f.recursive then mkEntriesForType f "directory" else mkFileEntry f;

      putterJson = {
        version = "1";
        state = putterStatePath;
        files = concatMap mkEntries (filter (f: f.enable) fileEntries);
      };

      putterJsonText = builtins.toJSON putterJson;
    in
    putterJsonText;
}
