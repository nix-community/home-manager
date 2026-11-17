{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkEnableOption mkOption types;

  cfg = config.wayland.windowManager.mango;
  variables = lib.concatStringsSep " " cfg.systemd.variables;
  extraCommands = lib.concatStringsSep " && " cfg.systemd.extraCommands;
  systemdActivation = "${pkgs.dbus}/bin/dbus-update-activation-environment --systemd ${variables}; ${extraCommands}";
  toMango =
    attrs:
    let
      flattenAttrs =
        set:
        let
          recurse =
            path:
            lib.concatMapAttrs (
              name: value:
              if builtins.isAttrs value then
                recurse (path ++ [ name ]) value
              else
                { ${builtins.concatStringsSep "_" (path ++ [ name ])} = value; }
            );
        in
        recurse [ ] set;
      mkConfig = lib.generators.toKeyValue {
        listsAsDuplicateKeys = true;
        mkKeyValue = lib.generators.mkKeyValueDefault { } " = ";
      };
    in
    mkConfig (flattenAttrs attrs);
in
{

  meta.maintainers = [ lib.maintainers.cktiel ];

  options = {
    wayland.windowManager.mango = {
      enable = mkEnableOption "Mango wayland compositor";

      package = lib.mkPackageOption pkgs "mango" {
        extraDescription = "package to use for mango";
      };
      systemd = {
        enable = mkOption {
          type = types.bool;
          default = pkgs.stdenv.hostPlatform.isLinux;
          example = false;
          description = ''
            Whether to enable {file}`mango-session.target` on
            mango startup. This links to
            {file}`graphical-session.target`.
            Some important environment variables will be imported to systemd
            and dbus user environment before reaching the target, including
            * {env}`DISPLAY`
            * {env}`WAYLAND_DISPLAY`
            * {env}`XDG_CURRENT_DESKTOP`
            * {env}`XDG_SESSION_TYPE`
            * {env}`NIXOS_OZONE_WL`
            You can extend this list using the `systemd.variables` option.
          '';
        };
        variables = mkOption {
          type = types.listOf types.str;
          default = [
            "DISPLAY"
            "WAYLAND_DISPLAY"
            "XDG_CURRENT_DESKTOP"
            "XDG_SESSION_TYPE"
            "NIXOS_OZONE_WL"
            "XCURSOR_THEME"
            "XCURSOR_SIZE"
          ];
          example = [ "--all" ];
          description = ''
            Environment variables imported into the systemd and D-Bus user environment.
          '';
        };
        extraCommands = mkOption {
          type = types.listOf types.str;
          default = [
            "systemctl --user reset-failed"
            "systemctl --user start mango-session.target"
          ];
          description = ''
            Extra commands to run after D-Bus activation.
          '';
        };
      };
      settings = mkOption {
        type = types.attrs;
        default = { };
        description = ''
          Mango configuration written in Nix. Entries with the same key
          should be written as lists. Variables and colors names should be
          quoted. See <https://mangowm.github.io/docs> for more examples.

          ::: {.note}
          This option uses a structured format that is converted to Mango's
          configuration syntax. Nested attributes are flattened with underscore separators.
          For example: `animation.duration_open = 400` becomes `animation_duration_open = 400`
          :::
        '';
        example = lib.literalExpression ''
          {
            # Window effects
            blur = 1;
            blur_optimized = 1;
            blur_params = {
              radius = 5;
              num_passes = 2;
            };
            border_radius = 6;
            focused_opacity = 1.0;

            # Animations - use underscores for multi-part keys
            animations = 1;
            animation_type_open = "slide";
            animation_type_close = "slide";
            animation_duration_open = 400;
            animation_duration_close = 800;

            # Or use nested attrs (will be flattened with underscores)
            animation_curve = {
              open = "0.46,1.0,0.29,1";
              close = "0.08,0.92,0,1";
            };

            # Use lists for duplicate keys like bind and tag_rule
            bind = [
              "SUPER,r,reload_config"
              "Alt,space,spawn,rofi -show drun"
              "Alt,Return,spawn,foot"
              "ALT,R,setkeymode,resize"  # Enter resize mode
            ];

            tag_rule = [
              "id:1,layout_name:tile"
              "id:2,layout_name:scroller"
            ];

          }
        '';
      };
      extraConfig = mkOption {
        type = types.lines;
        default = "";
        description = ''
          Extra configuration lines to add to `~/.config/mango/config.conf`.
          This is useful for advanced configurations that don't fit the structured
          settings format, or for options that aren't yet supported by the module.
        '';
        example = ''
          # Advanced config that doesn't fit structured format
          special_option = 1
        '';
      };
    };
  };
  config = lib.mkIf cfg.enable (
    let
      # mango has a 255 byte limit on configuration statements so i cant just put it all in one exec_once, i have to do it in a seperate file
      systemdFile = pkgs.writeTextFile {
        name = "systemd";
        text = systemdActivation;
        executable = true;
      };
      cfgText =
        toMango cfg.settings
        + lib.optionalString (cfg.systemd.enable) "exec_once = ${systemdFile}\n"
        + lib.optionalString (cfg.extraConfig != "") cfg.extraConfig;

      cfgFile = pkgs.writeTextFile {
        name = "config.conf";
        text = cfgText;
        checkPhase = "${lib.getExe cfg.package} -c $target -p || exit 1";
      };
    in
    {
      home.packages = [ cfg.package ];
      xdg.configFile."mango/config.conf" = lib.mkIf (cfg.settings != { } || cfg.extraConfig != "") {
        source = cfgFile;
      };
      systemd.user.targets.mango-session = lib.mkIf cfg.systemd.enable {
        Unit = {
          Description = "mango compositor session";
          Documentation = [ "man:systemd.special(7)" ];
          BindsTo = [ "graphical-session.target" ];
          Wants = [
            "graphical-session-pre.target"
          ];
          After = [ "graphical-session-pre.target" ];
        };
      };
    }
  );
}
