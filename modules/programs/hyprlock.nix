{ config, pkgs, lib, ... }:

with lib;

let

  cfg = config.programs.hyprlock;

in {
  meta.maintainers = [ maintainers.khaneliman maintainers.fufexan ];

  options.programs.hyprlock = {
    enable = mkEnableOption "" // {
      description = ''
        Whether to enable Hyprlock, Hyprland's GPU-accelerated lock screen
        utility.

        Note that PAM must be configured to enable hyprlock to perform
        authentication. The package installed through home-manager will *not* be
        able to unlock the session without this configuration.

        On NixOS, it can be enabled using:

        ```nix
        security.pam.services.hyprlock = {};
        ```
      '';
    };

    package = mkPackageOption pkgs "hyprlock" { };

    settings = lib.mkOption {
      type = with lib.types;
        let
          valueType = nullOr (oneOf [
            bool
            int
            float
            str
            path
            (attrsOf valueType)
            (listOf valueType)
          ]) // {
            description = "Hyprlock configuration value";
          };
        in valueType;
      default = { };
      example = lib.literalExpression ''
        {
          general = {
            disable_loading_bar = true;
            grace = 300;
            hide_cursor = true;
            no_fade_in = false;
          };

          background = [
            {
              path = "screenshot";
              blur_passes = 3;
              blur_size = 8;
            }
          ];

          input-field = [
            {
              size = "200, 50";
              position = "0, -80";
              monitor = "";
              dots_center = true;
              fade_on_empty = false;
              font_color = "rgb(202, 211, 245)";
              inner_color = "rgb(91, 96, 120)";
              outer_color = "rgb(24, 25, 38)";
              outline_thickness = 5;
              placeholder_text = '\'<span foreground="##cad3f5">Password...</span>'\';
              shadow_passes = 2;
            }
          ];
        }
      '';
      description = ''
        Hyprlock configuration written in Nix. Entries with the same key should
        be written as lists. Variables' and colors' names should be quoted. See
        <https://wiki.hyprland.org/Hypr-Ecosystem/hyprlock/> for more examples.
      '';
    };

    extraConfig = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = ''
        Extra configuration lines to add to `~/.config/hypr/hyprlock.conf`.
      '';
    };

    sourceFirst = lib.mkEnableOption ''
      putting source entries at the top of the configuration
    '' // {
      default = true;
    };

    importantPrefixes = lib.mkOption {
      type = with lib.types; listOf str;
      default = [ "$" "monitor" "size" ]
        ++ lib.optionals cfg.sourceFirst [ "source" ];
      example = [ "$" "monitor" "size" ];
      description = ''
        List of prefix of attributes to source at the top of the config.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    xdg.configFile."hypr/hyprlock.conf" =
      let shouldGenerate = cfg.extraConfig != "" || cfg.settings != { };
      in mkIf shouldGenerate {
        text = lib.optionalString (cfg.settings != { })
          (lib.hm.generators.toHyprconf {
            attrs = cfg.settings;
            inherit (cfg) importantPrefixes;
          }) + lib.optionalString (cfg.extraConfig != null) cfg.extraConfig;
      };
  };
}
