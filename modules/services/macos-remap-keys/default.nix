{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.macos-remap-keys;
  keytables = import ./keytables.nix { inherit lib; };

  keyToHIDCode = table: key: keytables.${table}.${key};

  # Note: hidutil requires HIDKeyboardModifierMapping values to be in hexadecimal
  # format rather than decimal JSON. Using hex strings instead of numbers will
  # crash macOS.
  makeMapping =
    table: from: to:
    ''{ "HIDKeyboardModifierMappingSrc": ${keyToHIDCode table from}, "HIDKeyboardModifierMappingDst": ${keyToHIDCode table to} }'';

  makeMappingsList =
    table: mappings: lib.mapAttrsToList (from: to: makeMapping table from to) mappings;

  allMappings =
    (makeMappingsList "keyboard" (cfg.keyboard or { }))
    ++ (makeMappingsList "keypad" (cfg.keypad or { }));

  allMappingsString = lib.concatStringsSep ", " allMappings;
  propertyString = ''{ "UserKeyMapping": [ ${allMappingsString} ] }'';
in
{
  meta.maintainers = [ lib.maintainers.WeetHet ];

  options.services.macos-remap-keys = {
    enable = lib.mkEnableOption "macOS key remapping service";

    keyboard = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      example = {
        Capslock = "Escape";
        SquareBracketOpen = "SquareBracketClose";
      };
      description = "Mapping of keyboard keys to remap";
    };

    keypad = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      example = {
        Enter = "Equal";
        Plus = "Minus";
      };
      description = "Mapping of keypad keys to remap";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.macos-remap-keys" pkgs lib.platforms.darwin)
    ];
    home.activation.macosRemapKeys = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      run --silence /usr/bin/hidutil property --set '${propertyString}'
    '';

    launchd.agents.remap-keys = {
      enable = true;
      config = {
        ProgramArguments = [
          "/usr/bin/hidutil"
          "property"
          "--set"
          propertyString
        ];
        KeepAlive.SuccessfulExit = false;
        RunAtLoad = true;
      };
    };
  };
}
