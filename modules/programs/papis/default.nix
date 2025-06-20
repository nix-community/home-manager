{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkOption types;

  cfg = config.programs.papis;

  defaultLibraries = lib.remove null (
    lib.mapAttrsToList (n: v: if v.isDefault then n else null) cfg.libraries
  );

  settingsIni = (lib.mapAttrs (n: v: v.settings) cfg.libraries) // {
    settings =
      cfg.settings
      // lib.optionalAttrs (cfg.libraries != { }) {
        "default-library" = lib.head defaultLibraries;
      };
  };

in
{
  meta.maintainers = [ ];

  options.programs.papis = {
    enable = lib.mkEnableOption "papis";

    package = lib.mkPackageOption pkgs "papis" { nullable = true; };

    settings = mkOption {
      type =
        with types;
        attrsOf (oneOf [
          bool
          int
          str
        ]);
      default = { };
      example = lib.literalExpression ''
        {
          editor = "nvim";
          file-browser = "ranger"
          add-edit = true;
        }
      '';
      description = ''
        Configuration written to
        {file}`$XDG_CONFIG_HOME/papis/config`. See
        <https://papis.readthedocs.io/en/latest/configuration.html>
        for supported values.
      '';
    };

    libraries = mkOption {
      type = types.attrsOf (
        types.submodule (
          { name, ... }:
          {
            options = {
              name = mkOption {
                type = types.str;
                default = name;
                readOnly = true;
                description = "This library's name.";
              };

              isDefault = mkOption {
                type = types.bool;
                default = false;
                example = true;
                description = ''
                  Whether this is a default library.

                  For papis to function without explicit library selection
                  (i.e. without `-l <library>` or `--pick-lib` flags) there
                  must be a default library defined.

                  Note this can be also defined (or overridden) on a local
                  `$(pwd)/.papis.config` or via python
                  `$XDG_CONFIG_HOME/papis/config.py` config file.
                '';
              };

              settings = mkOption {
                type =
                  with types;
                  attrsOf (oneOf [
                    bool
                    int
                    str
                  ]);
                default = { };
                example = lib.literalExpression ''
                  {
                    dir = "~/papers/";
                  }
                '';
                description = ''
                  Configuration for this library.
                '';
              };
            };
          }
        )
      );
      default = { };
      description = "Attribute set of papis libraries.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = lib.mkIf (cfg.package != null) [ cfg.package ];

    xdg.configFile."papis/config".text = lib.generators.toINI { } settingsIni;
  };
}
