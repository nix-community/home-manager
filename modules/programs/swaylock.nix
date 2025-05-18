{
  pkgs,
  config,
  lib,
  ...
}:
let
  cfg = config.programs.swaylock;
in
{
  meta.maintainers = [ lib.hm.maintainers.rcerc ];

  options.programs.swaylock = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = lib.versionOlder config.home.stateVersion "23.05" && (cfg.settings != { });
      defaultText = lib.literalExpression ''
        true  if state version < 23.05 and settings ≠ { },
        false otherwise
      '';
      example = true;
      description = ''
        Whether to enable swaylock.

        Note that PAM must be configured to enable swaylock to perform
        authentication. The package installed through home-manager
        will *not* be able to unlock the session without this
        configuration.

        On NixOS, this is by default enabled with the sway module, but
        for other compositors it can currently be enabled using:

        ```nix
        security.pam.services.swaylock = {};
        ```
      '';
    };

    package = lib.mkPackageOption pkgs "swaylock" { nullable = true; };

    settings = lib.mkOption {
      type =
        with lib.types;
        attrsOf (oneOf [
          bool
          float
          int
          path
          str
        ]);
      default = { };
      description = ''
        Default arguments to {command}`swaylock`. An empty set
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

  config = lib.mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "programs.swaylock" pkgs lib.platforms.linux)
    ];

    home.packages = lib.mkIf (cfg.package != null) [ cfg.package ];

    xdg.configFile."swaylock/config" = lib.mkIf (cfg.settings != { }) {
      text = lib.concatStrings (
        lib.mapAttrsToList (
          n: v:
          if v == false then
            ""
          else
            (if v == true then n else n + "=" + (if builtins.isPath v then "${v}" else builtins.toString v))
            + "\n"
        ) cfg.settings
      );
    };
  };
}
