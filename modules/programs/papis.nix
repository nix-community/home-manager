{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.papis;

  defaultLibraries = remove null
    (mapAttrsToList (n: v: if v.isDefault then n else null) cfg.libraries);

  settingsIni = (lib.mapAttrs (n: v: v.settings) cfg.libraries) // {
    settings = cfg.settings // { "default-library" = head defaultLibraries; };
  };

in {
  meta.maintainers = [ maintainers.marsam ];

  options.programs.papis = {
    enable = mkEnableOption "papis";

    settings = mkOption {
      type = with types; attrsOf (oneOf [ bool int str ]);
      default = { };
      example = literalExpression ''
        {
          editor = "nvim";
          file-browser = "ranger"
          add-edit = true;
        }
      '';
      description = ''
        Configuration written to
        <filename>$XDG_CONFIG_HOME/papis/config</filename>. See
        <link xlink:href="https://papis.readthedocs.io/en/latest/configuration.html"/>
        for supported values.
      '';
    };

    libraries = mkOption {
      type = types.attrsOf (types.submodule ({ config, name, ... }: {
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
              Whether this is a default library. There must be exactly one
              default library.
            '';
          };

          settings = mkOption {
            type = with types; attrsOf (oneOf [ bool int str ]);
            default = { };
            example = literalExpression ''
              {
                dir = "~/papers/";
              }
            '';
            description = ''
              Configuration for this library.
            '';
          };
        };
      }));
    };
  };

  config = mkIf cfg.enable {
    assertions = [{
      assertion = cfg.libraries == { } || length defaultLibraries == 1;
      message = "Must have exactly one default papis library, but found "
        + toString (length defaultLibraries)
        + optionalString (length defaultLibraries > 1)
        (", namely " + concatStringsSep "," defaultLibraries);
    }];

    home.packages = [ pkgs.papis ];

    xdg.configFile."papis/config" =
      mkIf (cfg.libraries != { }) { text = generators.toINI { } settingsIni; };
  };
}
