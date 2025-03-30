{ config, lib, pkgs, ... }:
let
  inherit (lib) mkOption types;

  cfg = config.programs.gnome-shell;

  extensionOpts = { config, ... }: {
    options = {
      id = mkOption {
        type = types.str;
        example = "user-theme@gnome-shell-extensions.gcampax.github.com";
        description = ''
          ID of the GNOME Shell extension. If not provided, it
          will be obtained from `package.extensionUuid`.
        '';
      };

      package = mkOption {
        type = types.package;
        example = "pkgs.gnome-shell-extensions";
        description = ''
          Package providing a GNOME Shell extension in
          `$out/share/gnome-shell/extensions/''${id}`.
        '';
      };
    };

    config = lib.mkIf (lib.hasAttr "extensionUuid" config.package) {
      id = lib.mkDefault config.package.extensionUuid;
    };
  };

  themeOpts = {
    options = {
      name = mkOption {
        type = types.str;
        example = "Plata-Noir";
        description = ''
          Name of the GNOME Shell theme.
        '';
      };

      package = mkOption {
        type = types.nullOr types.package;
        default = null;
        example = lib.literalExpression "pkgs.plata-theme";
        description = ''
          Package providing a GNOME Shell theme in
          `$out/share/themes/''${name}/gnome-shell`.
        '';
      };
    };
  };

in {
  meta.maintainers = [ lib.maintainers.terlar ];

  options.programs.gnome-shell = {
    enable = lib.mkEnableOption "GNOME Shell customization";

    extensions = mkOption {
      type = types.listOf (types.submodule extensionOpts);
      default = [ ];
      example = lib.literalExpression ''
        [
          { package = pkgs.gnomeExtensions.dash-to-panel; }
          {
            id = "user-theme@gnome-shell-extensions.gcampax.github.com";
            package = pkgs.gnome-shell-extensions;
          }
        ]
      '';
      description = ''
        List of GNOME Shell extensions.
      '';
    };

    theme = mkOption {
      type = types.nullOr (types.submodule themeOpts);
      default = null;
      example = lib.literalExpression ''
        {
          name = "Plata-Noir";
          package = pkgs.plata-theme;
        }
      '';
      description = ''
        Theme to use for GNOME Shell.
      '';
    };
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    (lib.mkIf (cfg.extensions != [ ]) {
      dconf.settings."org/gnome/shell" = {
        disable-user-extensions = false;
        enabled-extensions = lib.catAttrs "id" cfg.extensions;
      };

      home.packages = lib.catAttrs "package" cfg.extensions;
    })

    (lib.mkIf (cfg.theme != null) {
      dconf.settings."org/gnome/shell/extensions/user-theme".name =
        cfg.theme.name;

      programs.gnome-shell.extensions = [{
        id = "user-theme@gnome-shell-extensions.gcampax.github.com";
        package = pkgs.gnome-shell-extensions;
      }];

      home.packages = [ cfg.theme.package ];
    })
  ]);
}
