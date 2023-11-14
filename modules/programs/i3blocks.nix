{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.i3blocks;

  # Re-make the atom type for the INI files.
  # For some reason, the normal INI type seems to be incompatible with
  # DAG
  configAtomType = let
    # Keep the INI atom type here
    optType = with types; (nullOr (oneOf [ int bool str float ]));
  in types.mkOptionType {
    name = "INI config atom";
    description = "INI atom (null, int, bool, string, or float)";
    check = x: optType.check x;
    merge = (loc: defs: (optType.merge loc defs));
  };

  # Create the type of the actual config type
  configType = types.attrsOf configAtomType;

  # The INI generator
  mkIni = generators.toINI { };

in {
  meta.maintainers = [ maintainers.noodlez1232 ];

  options.programs.i3blocks = {
    enable = mkEnableOption "i3blocks i3 status command scheduler";

    package = mkOption {
      type = types.package;
      default = pkgs.i3blocks;
      defaultText = literalExpression "pkgs.i3blocks";
      description = "Package providing {command}`i3blocks`.";
    };

    bars = mkOption {
      type = with types; attrsOf (hm.types.dagOf configType);
      description = "Configuration written to i3blocks config";
      example = literalExpression ''
        {
          top = {
            # The title block
            title = {
              interval = "persist";
              command = "xtitle -s";
            };
          };
          bottom = {
            time = {
              command = "date +%r";
              interval = 1;
            };
            # Make sure this block comes after the time block
            date = lib.hm.dag.entryAfter [ "time" ] {
              command = "date +%d";
              interval = 5;
            };
            # And this block after the example block
            example = lib.hm.dag.entryAfter [ "date" ] {
              command = "echo hi $(date +%s)";
              interval = 3;
            };
          };
        }'';
    };
  };

  config = let
    # A function to create the file that will be put into the XDG config home.
    makeFile = config:
      let
        # Takes a singular name value pair and turns it into an attrset
        nameValuePairToAttr = value: (builtins.listToAttrs [ value ]);
        # Converts a dag entry to a name-value pair
        dagEntryToNameValue = entry: (nameValuePair entry.name entry.data);

        # Try to sort the blocks
        trySortedBlocks = hm.dag.topoSort config;

        # Get the blocks if successful, abort if not
        blocks = if trySortedBlocks ? result then
          trySortedBlocks.result
        else
          abort
          "Dependency cycle in i3blocks: ${builtins.toJSON trySortedBlocks}";

        # Turn the blocks back into their name value pairs
        orderedBlocks =
          (map (value: (nameValuePairToAttr (dagEntryToNameValue value)))
            blocks);
      in {
        # We create an "INI" file for each bar, then append them all in order
        text = concatStringsSep "\n" (map (value: (mkIni value)) orderedBlocks);
      };

    # Make our config (if enabled
  in mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "programs.i3blocks" pkgs
        lib.platforms.linux)
    ];

    home.packages = [ cfg.package ];

    xdg.configFile = (mapAttrs'
      (name: value: nameValuePair "i3blocks/${name}" (makeFile value))
      cfg.bars);
  };
}
