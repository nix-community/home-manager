{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (builtins) elem;
  inherit (lib.attrsets) recursiveUpdate;
  inherit (lib) lists getExe';
  inherit (lib.modules) mkIf;
  inherit (lib.options) mkEnableOption mkOption mkPackageOption;

  cfg = config.services.wayle;

  tomlFormat = pkgs.formats.toml { };
in
{
  meta.maintainers = with lib.maintainers; [
    isaacST08
    PerchunPak
  ];

  options.services.wayle = {
    enable = mkEnableOption "wayle shell";
    package = mkPackageOption pkgs "wayle" { };

    autoInstallDependencies = mkOption {
      type = lib.types.bool;
      default = true;
      example = false;
      description = ''
        Whether to automatically install soft dependencies used by wayle that
        will be required based on your config.
      '';
    };

    settings = mkOption {
      type = tomlFormat.type;
      description = ''
        Standard configuration options for wayle.
      '';

      default = { };

      example =
        lib.literalExpression
          # nix
          ''
            styling = {
              theme-provider = "wayle";

              palette = {
                bg = "#16161e";
                fg = "#c0caf5";
                primary = "#7aa2f7";
              };
            };

            bar = {
              scale = 1;
              location = "top";
              rounding = "sm";

              layout = {
                monitor = "*";
                left = ["clock"];
                center = ["media"];
                right = ["battery"];
              };
            };

            modules.clock = {
              format = "%H:%M";
              icon-show = true;
              label-show = true;
            };
          '';
    };
  };

  config = mkIf cfg.enable (
    let
      # Define default settings.
      settings = recursiveUpdate {
        wallpaper.engine-enabled = false;
        styling = {
          theme-provider = "wayle";
          wallust-apply-globally = true;
          pywal-apply-globally = true;
        };
      } cfg.settings;
    in
    {
      assertions = [
        (lib.hm.assertions.assertPlatform "services.wayle" pkgs lib.platforms.linux)
      ];

      home.packages = (
        [ cfg.package ]
        # Alias awww to swww.
        ++ (lists.optional settings.wallpaper.engine-enabled (
          pkgs.writeShellScriptBin "awww" ''
            exec swww "$@"
          ''
        ))
        # Install the appropriate theme-provider, if set.
        ++ (lists.optional (
          cfg.autoInstallDependencies
          && elem settings.styling.theme-provider [
            "matugen"
            "wallust"
            "pywal"
          ]
        ) pkgs.${settings.styling.theme-provider})
      );

      # Main config file.
      xdg.configFile."wayle/config.toml" = mkIf (cfg.settings != { }) {
        source = tomlFormat.generate "wayle-config" cfg.settings;
      };

      # Systemd service for main wayle shell.
      systemd.user.services.wayle = {
        Unit = {
          Description = ''
            Wayland Elements - A compositor agnostic shell with extensive customization
          '';
          Documentation = "https://github.com/wayle-rs/wayle";
          PartOf = [ config.wayland.systemd.target ];
          After = [ config.wayland.systemd.target ];
          ConditionEnvironment = "WAYLAND_DISPLAY";
        };
        Service = {
          ExecStart = "${getExe' cfg.package "wayle"} shell";
          Restart = "on-failure";
        };
        Install = {
          WantedBy = [ config.wayland.systemd.target ];
        };
      };

      # Wallpaper-engine dependency.
      services.swww.enable = mkIf settings.wallpaper.engine-enabled (lib.mkDefault true);
    }
  );
}
