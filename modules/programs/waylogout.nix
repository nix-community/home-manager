{ pkgs, config, lib, ... }:

with lib;

let cfg = config.programs.waylogout;
in {
  meta.maintainers = [ hm.maintainers.noodlez ];

  options.programs.waylogout = {
    enable = mkOption {
      default = false;
      type = lib.types.bool;
      example = true;
      description = ''
        Whether or not to enable waylogout.
      '';
    };

    package = mkPackageOption pkgs "waylogout" { };

    settings = mkOption {
      type = with types; attrsOf (oneOf [ bool float int str ]);
      default = { };
      description = ''
        Default arguments to {command}`waylogout`. An empty set
        disables configuration generation.
      '';
      example = {
        color = "808080";
        poweroff-command = "systemctl poweroff";
        reboot-command = "systemctl reboot";
        scaling = "fit";
        effect-blur = "7x4";
        screenshots = true;
      };
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "programs.waylogout" pkgs
        lib.platforms.linux)
    ];

    home.packages = [ cfg.package ];

    xdg.configFile."waylogout/config" = mkIf (cfg.settings != { }) {
      text = concatStrings (mapAttrsToList (n: v:
        if v == false then
          ""
        else
          (if v == true then n else n + "=" + builtins.toString v) + "\n")
        cfg.settings);
    };
  };
}
