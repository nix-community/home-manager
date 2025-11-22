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
      default = {
        # You can use it to add commands that run after AeroSpace startup.
        # Use after-startup-command instead.
        after-startup-command = [ ];

        # Start AeroSpace at login.
        # Use launch.enable instead
        start-at-login = false;

        # Normalizations. See: https://nikitabobko.github.io/AeroSpace/guide#normalization
        enable-normalization-flatten-containers = true;
        enable-normalization-opposite-orientation-for-nested-containers = true;

        # See: https://nikitabobko.github.io/AeroSpace/guide#layouts
        # The 'accordion-padding' specifies the size of accordion padding
        # You can set 0 to disable the padding feature
        accordion-padding = 30;

        # Possible values: tiles|accordion
        default-root-container-layout = "tiles";

        # Possible values: horizontal|vertical|auto
        # 'auto' means: wide monitor → horizontal, tall monitor → vertical
        default-root-container-orientation = "auto";

        # Mouse follows focus when focused monitor changes
        # Drop it from your config, if you don't like this behavior
        # Fallback value: on-focused-monitor-changed = []
        on-focused-monitor-changed = [ "move-mouse monitor-lazy-center" ];

        # Toggle disabling macOS "Hide application" (cmd-h)
        # https://nikitabobko.github.io/AeroSpace/goodies#disable-hide-app
        automatically-unhide-macos-hidden-apps = false;

        # Possible values: qwerty|dvorak|colemak
        # https://nikitabobko.github.io/AeroSpace/guide#key-mapping
        key-mapping.preset = "qwerty";

        # Gaps between windows and monitor edges.
        # Constant or per-monitor values.
        # https://nikitabobko.github.io/AeroSpace/guide#assign-workspaces-to-monitors
        gaps = {
          inner = {
            horizontal = 0;
            vertical = 0;
          };
          outer = {
            left = 0;
            bottom = 0;
            top = 0;
            right = 0;
          };
        };

        # Binding modes
        # https://nikitabobko.github.io/AeroSpace/guide#binding-modes
        mode = {
          # --- main mode ---
          main.binding = {

            # Layout switching
            alt-slash = "layout tiles horizontal vertical";
            alt-comma = "layout accordion horizontal vertical";

            # Focus movement
            alt-h = "focus left";
            alt-j = "focus down";
            alt-k = "focus up";
            alt-l = "focus right";

            # Move window
            alt-shift-h = "move left";
            alt-shift-j = "move down";
            alt-shift-k = "move up";
            alt-shift-l = "move right";

            # Resize smart
            alt-minus = "resize smart -50";
            alt-equal = "resize smart +50";

            # Workspaces 1–9
            alt-1 = "workspace 1";
            alt-2 = "workspace 2";
            alt-3 = "workspace 3";
            alt-4 = "workspace 4";
            alt-5 = "workspace 5";
            alt-6 = "workspace 6";
            alt-7 = "workspace 7";
            alt-8 = "workspace 8";
            alt-9 = "workspace 9";

            # Named workspaces
            alt-a = "workspace A";
            alt-b = "workspace B";
            alt-c = "workspace C";
            alt-d = "workspace D";
            alt-e = "workspace E";
            alt-f = "workspace F";
            alt-g = "workspace G";
            alt-i = "workspace I";
            alt-m = "workspace M";
            alt-n = "workspace N";
            alt-o = "workspace O";
            alt-p = "workspace P";
            alt-q = "workspace Q";
            alt-r = "workspace R";
            alt-s = "workspace S";
            alt-t = "workspace T";
            alt-u = "workspace U";
            alt-v = "workspace V";
            alt-w = "workspace W";
            alt-x = "workspace X";
            alt-y = "workspace Y";
            alt-z = "workspace Z";

            # Move node to workspace
            alt-shift-1 = "move-node-to-workspace 1";
            alt-shift-2 = "move-node-to-workspace 2";
            alt-shift-3 = "move-node-to-workspace 3";
            alt-shift-4 = "move-node-to-workspace 4";
            alt-shift-5 = "move-node-to-workspace 5";
            alt-shift-6 = "move-node-to-workspace 6";
            alt-shift-7 = "move-node-to-workspace 7";
            alt-shift-8 = "move-node-to-workspace 8";
            alt-shift-9 = "move-node-to-workspace 9";

            alt-shift-a = "move-node-to-workspace A";
            alt-shift-b = "move-node-to-workspace B";
            alt-shift-c = "move-node-to-workspace C";
            alt-shift-d = "move-node-to-workspace D";
            alt-shift-e = "move-node-to-workspace E";
            alt-shift-f = "move-node-to-workspace F";
            alt-shift-g = "move-node-to-workspace G";
            alt-shift-i = "move-node-to-workspace I";
            alt-shift-m = "move-node-to-workspace M";
            alt-shift-n = "move-node-to-workspace N";
            alt-shift-o = "move-node-to-workspace O";
            alt-shift-p = "move-node-to-workspace P";
            alt-shift-q = "move-node-to-workspace Q";
            alt-shift-r = "move-node-to-workspace R";
            alt-shift-s = "move-node-to-workspace S";
            alt-shift-t = "move-node-to-workspace T";
            alt-shift-u = "move-node-to-workspace U";
            alt-shift-v = "move-node-to-workspace V";
            alt-shift-w = "move-node-to-workspace W";
            alt-shift-x = "move-node-to-workspace X";
            alt-shift-y = "move-node-to-workspace Y";
            alt-shift-z = "move-node-to-workspace Z";

            # Workspace back and forth
            alt-tab = "workspace-back-and-forth";

            # Move workspace to monitor
            alt-shift-tab = "move-workspace-to-monitor --wrap-around next";

            # Switch to service mode
            alt-shift-semicolon = "mode service";
          };

          # --- service mode ---
          service.binding = {
            esc = [
              "reload-config"
              "mode main"
            ];
            r = [
              "flatten-workspace-tree"
              "mode main"
            ];
            f = [
              "layout floating tiling"
              "mode main"
            ];
            backspace = [
              "close-all-windows-but-current"
              "mode main"
            ];

            # Join with adjacent container
            alt-shift-h = [
              "join-with left"
              "mode main"
            ];
            alt-shift-j = [
              "join-with down"
              "mode main"
            ];
            alt-shift-k = [
              "join-with up"
              "mode main"
            ];
            alt-shift-l = [
              "join-with right"
              "mode main"
            ];

            # Media keys
            down = "volume down";
            up = "volume up";
            shift-down = [
              "volume set 0"
              "mode main"
            ];
          };
        };
      };
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
          on-window-detected = [
            {
              "if".app-id = "com.apple.finder";
              run = "move-node-to-workspace 9";
            }

            {
              "if" = {
                app-id = "com.apple.systempreferences";
                app-name-regex-substring = "settings";
                window-title-regex-substring = "substring";
                workspace = "workspace-name";
                during-aerospace-startup = true;
              };
              check-further-callbacks = true;
              run = [
                "layout floating"
                "move-node-to-workspace S"
              ];
            }
          ];
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

      # 1. Fail if user sets start-at-login = true BUT launchd is disabled.
      {
        assertion =
          !((lib.hasAttr "start-at-login" cfg.settings) && (cfg.settings."start-at-login" == true))
          || (cfg.launchd.enable == true);
        message = ''
          You have set `programs.aerospace.settings."start-at-login" = true;`
          but `programs.aerospace.launchd.enable` is false.

          This tells AeroSpace to manage its own startup, which can conflict
          with Home Manager.

          To manage startup with Home Manager, please set
          `programs.aerospace.launchd.enable = true;`
          (You can leave `start-at-login = true` in your settings, it will be
          correctly overridden).
        '';
      }

      # 2. Fail if user sets after-login-command (in any case).
      {
        assertion =
          !(
            (lib.hasAttr "after-login-command" cfg.settings)
            && (lib.isList cfg.settings."after-login-command")
            && (cfg.settings."after-login-command" != [ ])
          );
        message = ''
          You have set `programs.aerospace.settings."after-login-command"`.

          This setting is not supported when using this Home Manager module,
          as it either conflicts with the launchd service (if enabled)
          or bypasses it (if disabled).

          The correct way to run commands after AeroSpace starts is to use:
          1. `programs.aerospace.launchd.enable = true;`
          2. `programs.aerospace.settings."after-startup-command" = [ ... ];`
        '';
      }
    ];

    home = {
      packages = lib.mkIf (cfg.package != null) [ cfg.package ];

      file.".config/aerospace/aerospace.toml" = {
        source = tomlFormat.generate "aerospace" (
          filterNulls (
            cfg.settings
            // {
              # Override these to avoid launchd conflicts
              start-at-login = false;
              after-login-command = [ ];
            }
          )
        );

        onChange = lib.mkIf cfg.launchd.enable ''
          echo "AeroSpace config changed, reloading..."
          ${lib.getExe cfg.package} reload-config
        '';
      };
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
