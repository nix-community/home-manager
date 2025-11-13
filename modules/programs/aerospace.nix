{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkOption types;
  cfg = config.programs.aerospace;

  tomlFormat = pkgs.formats.toml { };

  # filterAttrsRecursive supporting lists, as well.
  filterListAndAttrsRecursive =
    pred: set:
    lib.listToAttrs (
      lib.concatMap (
        name:
        let
          v = set.${name};
        in
        if pred v then
          [
            (lib.nameValuePair name (
              if lib.isAttrs v then
                filterListAndAttrsRecursive pred v
              else if lib.isList v then
                (map (i: if lib.isAttrs i then filterListAndAttrsRecursive pred i else i) (lib.filter pred v))
              else
                v
            ))
          ]
        else
          [ ]
      ) (lib.attrNames set)
    );
  filterNulls = filterListAndAttrsRecursive (v: v != null);
in
{
  meta.maintainers = with lib.maintainers; [ damidoug ];

  imports = [
    (lib.mkRenamedOptionModule
      [ "programs" "aerospace" "userSettings" ]
      [ "programs" "aerospace" "settings" ]
    )
  ];

  options.programs.aerospace = {
    enable = lib.mkEnableOption "AeroSpace window manager";

    package = lib.mkPackageOption pkgs "aerospace" { nullable = true; };

    launchd = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Configure the launchd agent to manage the AeroSpace process.

          The first time this is enabled, macOS will prompt you to allow this background
          item in System Settings.

          You can verify the service is running correctly from your terminal.
          Run: `launchctl list | grep aerospace`

          - A running process will show a Process ID (PID) and a status of 0, for example:
            `12345	0	org.nix-community.home.aerospace`

          - If the service has crashed or failed to start, the PID will be a dash and the
            status will be a non-zero number, for example:
            `-	1	org.nix-community.home.aerospace`

          In case of failure, check the logs with `cat /tmp/aerospace.err.log`.

          For more detailed service status, run `launchctl print gui/$(id -u)/org.nix-community.home.aerospace`.

          NOTE: Enabling this option will configure AeroSpace to **not** manage its own
          launchd agent. Specifically, it will set `start-at-login = false` and
          `after-login-command = []` in the configuration file, as those are now handled
          by Home Manager and launchd instead.
        '';
      };
      keepAlive = mkOption {
        type = types.bool;
        default = true;
        description = "Whether the launchd service should be kept alive.";
      };
    };

    settings = mkOption {
      inherit (tomlFormat) type;
      default = { };
      example = lib.literalExpression ''
        {
          gaps = {
            outer.left = 8;
            outer.bottom = 8;
            outer.top = 8;
            outer.right = 8;
          };
          mode.main.binding = {
            alt-h = "focus left";
            alt-j = "focus down";
            alt-k = "focus up";
            alt-l = "focus right";
          };
        }
      '';
      description = ''
        AeroSpace configuration, see
        <https://nikitabobko.github.io/AeroSpace/guide#configuring-aerospace>
        for supported values.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "programs.aerospace" pkgs lib.platforms.darwin)
    ];

    home = {
      packages = lib.mkIf (cfg.package != null) [ cfg.package ];

      file.".config/aerospace/aerospace.toml".source = tomlFormat.generate "aerospace" (
        filterNulls (
          cfg.settings
          // lib.optionalAttrs cfg.launchd.enable {
            # Override these to avoid launchd conflicts
            start-at-login = false;
            after-login-command = [ ];
          }
        )
      );
    };

    launchd.agents.aerospace = {
      enable = cfg.launchd.enable;
      config = {
        Program = "${cfg.package}/Applications/AeroSpace.app/Contents/MacOS/AeroSpace";
        KeepAlive = cfg.launchd.keepAlive;
        RunAtLoad = true;
        StandardOutPath = "/tmp/aerospace.log";
        StandardErrorPath = "/tmp/aerospace.err.log";
      };
    };
  };
}
