{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.wayprompt;

  # Matches 6-hex-digit RGB or 8-hex-digit RGBA values
  colourHexPattern = "^[0-9a-fA-F]{6}([0-9a-fA-F]{2})?$";

  isColourHex = str: builtins.match colourHexPattern str != null;

  iniFormat = pkgs.formats.ini {
    mkKeyValue = lib.generators.mkKeyValueDefault {
      mkValueString =
        v:
        if lib.isString v then
          (if isColourHex v then "0x${lib.strings.toUpper v};" else ''"${v}";'')
        else
          lib.generators.mkValueStringDefault { } v + ";";
    } " = ";
  };
in
{
  meta.maintainers = [ lib.maintainers.panchoh ];

  options.programs.wayprompt = {
    enable = lib.mkEnableOption "Wayprompt, a password-prompter for Wayland";

    package = lib.mkPackageOption pkgs "wayprompt" { nullable = true; };

    settings = lib.mkOption {
      inherit (iniFormat) type;
      default = { };
      example = lib.literalExpression ''
        {
          general = {
            font-regular = "sans:size=14";
            pin-square-amount = 32;
          };
          colours = {
            background = "ffffffaa";
          };
        }
      '';
      description = ''
        Configuration for wayprompt written to
        {file}`$XDG_CONFIG_HOME/wayprompt/config.ini`.
        See {manpage}`wayprompt(5)` for a list of available options.
        Note that colours can be either 6-hex-digit RGB or 8-hex-digit RGBA values.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "programs.wayprompt" pkgs lib.platforms.linux)
    ];

    home.packages = lib.mkIf (cfg.package != null) [ cfg.package ];

    xdg.configFile."wayprompt/config.ini" = lib.mkIf (cfg.settings != { }) {
      source = iniFormat.generate "config.ini" cfg.settings;
    };
  };
}
