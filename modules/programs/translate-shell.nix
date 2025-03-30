{ config, lib, pkgs, ... }:
let
  cfg = config.programs.translate-shell;

  mkKeyValue = key: value:
    let
      formatValue = v:
        if lib.isBool v then
          (if v then "true" else "false")
        else if lib.isString v then
          ''"${v}"''
        else if lib.isList v then
          "[ ${lib.concatStringsSep " " (map formatValue v)} ]"
        else
          toString v;
    in ":${key} ${formatValue value}";

  toKeyValue = lib.generators.toKeyValue { inherit mkKeyValue; };

in {
  meta.maintainers = [ ];

  options.programs.translate-shell = {
    enable = lib.mkEnableOption "translate-shell";

    settings = lib.mkOption {
      type = with lib.types; attrsOf (oneOf [ bool str (listOf str) ]);
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

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.translate-shell ];

    xdg.configFile."translate-shell/init.trans" =
      lib.mkIf (cfg.settings != { }) { text = "{${toKeyValue cfg.settings}}"; };
  };
}
