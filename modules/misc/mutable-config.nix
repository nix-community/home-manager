{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib)
    attrNames
    attrValues
    concatStringsSep
    elem
    filter
    filterAttrs
    hasSuffix
    literalExpression
    mapAttrsToList
    mkIf
    mkOption
    toLower
    types
    ;

  inherit (config.home) homeDirectory;

  inherit
    (
      (import ../lib/file-type.nix {
        inherit homeDirectory lib pkgs;
      })
    )
    normalizeAbsPath
    ;

  cfg = config.home.mutableConfig;
  enabledEntries = filterAttrs (_: entry: entry.enable && entry.data != { }) cfg;
  enabledPaths = attrNames enabledEntries;
  homeFileTargets = map (file: file.target) (attrValues config.home.file);
  homeFileConflicts = filter (
    path:
    elem (normalizeAbsPath {
      inherit path;
      basePath = homeDirectory;
    }) homeFileTargets
  ) enabledPaths;

  inferFormat =
    path:
    let
      lower = toLower path;
    in
    if hasSuffix ".toml" lower then
      "toml"
    else if hasSuffix ".json" lower || hasSuffix ".jsonc" lower then
      "json"
    else if hasSuffix ".ini" lower || hasSuffix ".cfg" lower then
      "ini"
    else
      throw "cannot infer mutable config format for ${path}; set format explicitly";
in
{
  options.home.mutableConfig = mkOption {
    type = types.attrsOf (
      types.submodule {
        options = {
          enable = mkOption {
            type = types.bool;
            default = true;
            description = "Whether to manage this file.";
          };

          format = mkOption {
            type = types.enum [
              "auto"
              "toml"
              "json"
              "ini"
            ];
            default = "auto";
            description = ''
              File format of the file. If unspecified or "auto",
              format is detected based on file extension.
            '';
          };

          data = mkOption {
            type = types.anything;
            default = { };
            example = literalExpression ''
              {
                # This key will be overwritten by home-manager.
                managedKey = "managed value";

                # Other fields on nestedObject will be preserved.
                nestedObject = {
                  justOne = "managed field";
                };

                # This key will be removed, if it exists.
                staleKey = config.lib.mutableConfig.remove;

                # The list contained in this key will have an element appended
                # if it doesn't have that element.
                listKey = config.lib.mutableConfig.union [ "managed item" ];

                # For a list of objects, this will look up an existing object by
                # the "label" key and deep merge the inner fields.
                # If no object matches `label=Format`, a new one will be inserted.
                tasks = config.lib.mutableConfig.mergeBy "label" [
                  {
                    label = "Format";
                    command = "nix";
                    # NOTE: the merge is recursive, so we could use another
                    #       `union` right here, for example.
                    args = [ "fmt" ];
                  }
                ];
              }
            '';
            description = ''
              Data to merge into the existing file.
              For object and table files, keys not present here are preserved.

              Specific keys can be removed explicitly by using the `remove`
              sentinel. For lists and arrays, you can use the `union` operator
              to ensure values will be added if not already present.
              For lists of objects, `mergeBy` is available - it finds the object
              in the list by looking up a specific key, then merging in the other
              properties. If no record by that key exists, it gets appended.

              For top-level JSON arrays, use
              {option}`config.lib.mutableConfig.union` or
              {option}`config.lib.mutableConfig.mergeBy`.
            '';
          };

          failOnInvalid = mkOption {
            type = types.bool;
            default = false;
            description = "Whether to fail activation when the existing file cannot be parsed.";
          };

          onInvalid = mkOption {
            type = types.enum [
              "skip"
              "initialize"
            ];
            default = "skip";
            description = ''
              How to handle an invalid existing file when {option}`failOnInvalid`
              is disabled. The value `skip` leaves the file untouched, while
              `initialize` treats it as an empty file and applies managed keys.
            '';
          };
        };
      }
    );
    default = { };
    description = ''
      Patch specific properties on complex or mutable structured configuration files.
      This manages only a subset of values of the overall file.

      Unlike {option}`home.file` and {option}`xdg.configFile`, these files are
      plain files in the home directory. Home Manager manages only the keys
      declared in {option}`data`, so applications may continue to modify other settings.
    '';
  };

  config = lib.mkMerge [
    {
      assertions = [
        {
          assertion = homeFileConflicts == [ ];
          message = "home.mutableConfig conflicts with home.file for paths: ${concatStringsSep ", " homeFileConflicts}";
        }
      ];
    }

    (mkIf (enabledPaths != [ ]) (
      let
        python = pkgs.python3.withPackages (ps: [
          ps.json5
          ps.tomlkit
        ]);

        manifestJson = builtins.toJSON (
          mapAttrsToList (path: entry: {
            path = normalizeAbsPath {
              inherit path;
              basePath = homeDirectory;
            };
            format = if entry.format == "auto" then inferFormat path else entry.format;
            fail_on_invalid = entry.failOnInvalid;
            on_invalid = entry.onInvalid;
            managed = entry.data;
          }) enabledEntries
        );

        manifestFile = pkgs.writeText "hm-mutable-config-manifest.json" manifestJson;
      in
      {
        home.activation.mutableConfigMerge = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
          ${python}/bin/python ${./mutable-config.py} ${manifestFile} ${lib.escapeShellArg homeDirectory}
        '';
      }
    ))
  ];
}
