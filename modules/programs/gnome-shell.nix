{ config, lib, pkgs, ... }:

with lib;
let
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
        example = "pkgs.gnome.gnome-shell-extensions";
        description = ''
          Package providing a GNOME Shell extension in
          `$out/share/gnome-shell/extensions/''${id}`.
        '';
      };
    };

    config = mkIf (hasAttr "extensionUuid" config.package) {
      id = mkDefault config.package.extensionUuid;
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
        example = literalExpression "pkgs.plata-theme";
        description = ''
          Package providing a GNOME Shell theme in
          `$out/share/themes/''${name}/gnome-shell`.
        '';
      };
    };
  };

in {
  meta.maintainers = [ maintainers.terlar ];

  options.programs.gnome-shell = {
    enable = mkEnableOption "GNOME Shell customization";

    extensions = mkOption {
      type = types.listOf (types.submodule extensionOpts);
      default = [ ];
      example = literalExpression ''
        [
          { package = pkgs.gnomeExtensions.dash-to-panel; }
          {
            id = "user-theme@gnome-shell-extensions.gcampax.github.com";
            package = pkgs.gnome.gnome-shell-extensions;
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
      example = literalExpression ''
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

  config = mkIf cfg.enable (mkMerge [
    (mkIf (cfg.extensions != [ ]) {
      dconf.settings."org/gnome/shell" = {
        disable-user-extensions = false;
        enabled-extensions = catAttrs "id" cfg.extensions;
      };

      home.packages = catAttrs "package" cfg.extensions;
    })

    (mkIf (cfg.theme != null) {
      dconf.settings."org/gnome/shell/extensions/user-theme".name =
        cfg.theme.name;

      programs.gnome-shell.extensions = [{
        id = "user-theme@gnome-shell-extensions.gcampax.github.com";
        package = pkgs.gnome.gnome-shell-extensions;
      }];

      home.packages = [ cfg.theme.package ];
    })
  ]);
}
