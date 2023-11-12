{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.translate-shell;

  mkKeyValue = key: value:
    let
      formatValue = v:
        if isBool v then
          (if v then "true" else "false")
        else if isString v then
          ''"${v}"''
        else if isList v then
          "[ ${concatStringsSep " " (map formatValue v)} ]"
        else
          toString v;
    in ":${key} ${formatValue value}";

  toKeyValue = generators.toKeyValue { inherit mkKeyValue; };

in {
  meta.maintainers = [ ];

  options.programs.translate-shell = {
    enable = mkEnableOption "translate-shell";

    settings = mkOption {
      type = with types; attrsOf (oneOf [ bool str (listOf str) ]);
      default = { };
      example = {
        verbose = true;
        hl = "en";
        tl = [ "es" "fr" ];
      };
      description = ''
        Options to add to {file}`$XDG_CONFIG_HOME/translate-shell/init.trans` file.
        See <https://github.com/soimort/translate-shell/wiki/Configuration>
        for options.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.translate-shell ];

    xdg.configFile."translate-shell/init.trans" =
      mkIf (cfg.settings != { }) { text = "{${toKeyValue cfg.settings}}"; };
  };
}
