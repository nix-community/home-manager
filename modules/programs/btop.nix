{ config, lib, pkgs, ... }:
let
  cfg = config.programs.btop;

  finalConfig = let
    toKeyValue = lib.generators.toKeyValue {
      mkKeyValue = lib.generators.mkKeyValueDefault {
        mkValueString = v:
          with builtins;
          if isBool v then
            (if v then "True" else "False")
          else if isString v then
            ''"${v}"''
          else
            toString v;
      } " = ";
    };
  in ''
    ${toKeyValue cfg.settings}
    ${lib.optionalString (cfg.extraConfig != "") cfg.extraConfig}
  '';
in {
  meta.maintainers = with lib.maintainers; [ GaetanLepage khaneliman ];

  options.programs.btop = {
    enable = lib.mkEnableOption "btop";

    package = lib.mkPackageOption pkgs "btop" { };

    settings = lib.mkOption {
      type = with lib.types; attrsOf (oneOf [ bool float int str ]);
      default = { };
      example = {
        color_theme = "Default";
        theme_background = false;
      };
      description = ''
        Options to add to {file}`btop.conf` file.
        See <https://github.com/aristocratos/btop#configurability>
        for options.
      '';
    };

    extraConfig = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = ''
        Extra lines added to the {file}`btop.conf` file.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];

    xdg.configFile."btop/btop.conf" =
      lib.mkIf (cfg.settings != { }) { text = finalConfig; };
  };
}
