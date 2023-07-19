{ config, options, lib, pkgs, ... }:

with lib;

let

  cfg = config.home.pointerCursor;

  pointerCursorModule = types.submodule {
    options = {
      package = mkOption {
        type = types.package;
        example = literalExpression "pkgs.vanilla-dmz";
        description = "Package providing the cursor theme.";
      };

      name = mkOption {
        type = types.str;
        example = "Vanilla-DMZ";
        description = "The cursor name within the package.";
      };

      size = mkOption {
        type = types.int;
        default = 32;
        example = 64;
        description = "The cursor size.";
      };

      x11 = {
        enable = mkEnableOption ''
          x11 config generation for {option}`home.pointerCursor`
        '';

        defaultCursor = mkOption {
          type = types.str;
          default = "left_ptr";
          example = "X_cursor";
          description = "The default cursor file to use within the package.";
        };
      };

      gtk = {
        enable = mkEnableOption ''
          gtk config generation for {option}`home.pointerCursor`
        '';
      };
    };
  };

  cursorPath = "${cfg.package}/share/icons/${escapeShellArg cfg.name}/cursors/${
      escapeShellArg cfg.x11.defaultCursor
    }";

in {
  meta.maintainers = [ maintainers.polykernel maintainers.league ];

  imports = [
    (mkAliasOptionModule [ "xsession" "pointerCursor" "package" ] [
      "home"
      "pointerCursor"
      "package"
    ])
    (mkAliasOptionModule [ "xsession" "pointerCursor" "name" ] [
      "home"
      "pointerCursor"
      "name"
    ])
    (mkAliasOptionModule [ "xsession" "pointerCursor" "size" ] [
      "home"
      "pointerCursor"
      "size"
    ])
    (mkAliasOptionModule [ "xsession" "pointerCursor" "defaultCursor" ] [
      "home"
      "pointerCursor"
      "x11"
      "defaultCursor"
    ])

    ({ ... }: {
      warnings = optional (any (x:
        getAttrFromPath
        ([ "xsession" "pointerCursor" ] ++ [ x ] ++ [ "isDefined" ])
        options) [ "package" "name" "size" "defaultCursor" ]) ''
          The option `xsession.pointerCursor` has been merged into `home.pointerCursor` and will be removed
          in the future. Please change to set `home.pointerCursor` directly and enable `home.pointerCursor.x11.enable`
          to generate x11 specific cursor configurations. You can refer to the documentation for more details.
        '';
    })
  ];

  options = {
    home.pointerCursor = mkOption {
      type = types.nullOr pointerCursorModule;
      default = null;
      description = ''
        Cursor configuration. Set to `null` to disable.

        Top-level options declared under this submodule are backend independent
        options. Options declared under namespaces such as `x11`
        are backend specific options. By default, only backend independent cursor
        configurations are generated. If you need configurations for specific
        backends, you can toggle them via the enable option. For example,
        [](#opt-home.pointerCursor.x11.enable)
        will enable x11 cursor configurations.

        Note that this will merely generate the cursor configurations.
        To apply the configurations, the relevant subsytems must also be configured.
        For example, [](#opt-home.pointerCursor.gtk.enable) will generate
        the gtk cursor configuration, but [](#opt-gtk.enable) needs
        to be set for it to be applied.
      '';
    };
  };

  config = mkIf (cfg != null) (mkMerge [
    {
      assertions = [
        (hm.assertions.assertPlatform "home.pointerCursor" pkgs platforms.linux)
      ];

      home.packages = [ cfg.package ];

      # Set name in icons theme, for compatibility with AwesomeWM etc. See:
      # https://github.com/nix-community/home-manager/issues/2081
      # https://wiki.archlinux.org/title/Cursor_themes#XDG_specification
      xdg.dataFile."icons/default/index.theme".text = ''
        [icon theme]
        Name=Default
        Comment=Default Cursor Theme
        Inherits=${cfg.name}
      '';

      # Set directory to look for cursors in, needed for some applications
      # that are unable to find cursors otherwise. See:
      # https://github.com/nix-community/home-manager/issues/2812
      # https://wiki.archlinux.org/title/Cursor_themes#Environment_variable
      home.sessionVariables = {
        XCURSOR_PATH = mkDefault ("$XCURSOR_PATH\${XCURSOR_PATH:+:}"
          + "${config.home.profileDirectory}/share/icons");
        XCURSOR_SIZE = mkDefault cfg.size;
        XCURSOR_THEME = mkDefault cfg.name;
      };
    }

    (mkIf cfg.x11.enable {
      xsession.initExtra = ''
        ${pkgs.xorg.xsetroot}/bin/xsetroot -xcf ${cursorPath} ${
          toString cfg.size
        }
      '';

      xresources.properties = {
        "Xcursor.theme" = cfg.name;
        "Xcursor.size" = cfg.size;
      };
    })

    (mkIf cfg.gtk.enable {
      gtk.cursorTheme = mkDefault { inherit (cfg) package name size; };
    })
  ]);
}
