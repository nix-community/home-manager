{ pkgs, config, lib, ... }:
let cfg = config.programs.waylogout;
in {
  meta.maintainers = [ lib.hm.maintainers.noodlez ];

  options.programs.waylogout = {
    enable = lib.mkOption {
      default = false;
      type = lib.types.bool;
      example = true;
      description = ''
        Whether or not to enable waylogout.
      '';
    };

    package = lib.mkPackageOption pkgs "waylogout" { nullable = true; };

    settings = lib.mkOption {
      type = with lib.types; attrsOf (oneOf [ bool float int path str ]);
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

  config = lib.mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "programs.waylogout" pkgs
        lib.platforms.linux)
    ];

    home.packages = lib.mkIf (cfg.package != null) [ cfg.package ];

    xdg.configFile."waylogout/config" = lib.mkIf (cfg.settings != { }) {
      text = lib.concatStrings (lib.mapAttrsToList (n: v:
        if v == false then
          ""
        else
          (if v == true then n else n + "=" + builtins.toString v) + "\n")
        cfg.settings);
    };
  };
}
