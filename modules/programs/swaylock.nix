{ pkgs, config, lib, ... }:

with lib;

let cfg = config.programs.swaylock;
in {
  meta.maintainers = [ hm.maintainers.rcerc ];

  options.programs.swaylock = {
    enable = mkOption {
      type = lib.types.bool;
      default = versionOlder config.home.stateVersion "23.05"
        && (cfg.settings != { });
      defaultText = literalExpression ''
        true  if state version < 23.05 and settings ≠ { },
        false otherwise
      '';
      example = true;
      description = "Whether to enable swaylock.";
    };

    package = mkPackageOption pkgs "swaylock" { };

    settings = mkOption {
      type = with types; attrsOf (oneOf [ bool float int str ]);
      default = { };
      description = ''
        Default arguments to <command>swaylock</command>. An empty set
        disables configuration generation.
      '';
      example = {
        color = "808080";
        font-size = 24;
        indicator-idle-visible = false;
        indicator-radius = 100;
        line-color = "ffffff";
        show-failed-attempts = true;
      };
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    xdg.configFile."swaylock/config" = mkIf (cfg.settings != { }) {
      text = concatStrings (mapAttrsToList (n: v:
        if v == false then
          ""
        else
          (if v == true then n else n + "=" + builtins.toString v) + "\n")
        cfg.settings);
    };
  };
}
