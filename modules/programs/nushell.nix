{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.nushell;

  tomlFormat = pkgs.formats.toml { };

  linesOrSource = name:
    types.submodule ({ config, ... }: {
      options = {
        text = mkOption {
          type = types.lines;
          default = "";
          description = ''
            Text of the nushell <filename>${name}</filename> file.
            If unset then the source option will be preferred.
          '';
        };

        source = mkOption {
          type = types.nullOr types.path;
          default = pkgs.writeTextFile {
            inherit (config) text;
            name = hm.strings.storeFileName name;
          };
          defaultText = literalExpression "file containing text";
          description = ''
            Path of the nushell <filename>${name}</filename> file to use.
          '';
        };
      };
    });

in {
  meta.maintainers = [ maintainers.Philipp-M ];

  imports = [
    (mkRemovedOptionModule [ "programs" "nushell" "settings" ] ''
      Please use

        'programs.nushell.configFile' and 'programs.nushell.envFile'

      instead.
    '')
  ];

  options.programs.nushell = {
    enable = mkEnableOption "nushell";

    package = mkOption {
      type = types.package;
      default = pkgs.nushell;
      defaultText = literalExpression "pkgs.nushell";
      description = "The package to use for nushell.";
    };

    configFile = mkOption {
      type = types.nullOr (linesOrSource "config.nu");
      default = null;
      example = literalExpression ''
        { text = '''
            let $config = {
              filesize_metric: false
              table_mode: rounded
              use_ls_colors: true
            }
          ''';
        }
      '';
      description = ''
        The configuration file to be used for nushell.
        </para>
        <para>
        See <link xlink:href="https://www.nushell.sh/book/configuration.html#configuration" /> for more information.
      '';
    };

    envFile = mkOption {
      type = types.nullOr (linesOrSource "env.nu");
      default = null;
      example = ''
        let-env FOO = 'BAR'
      '';
      description = ''
        The environment variables file to be used for nushell.
        </para>
        <para>
        See <link xlink:href="https://www.nushell.sh/book/configuration.html#configuration" /> for more information.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    xdg.configFile = mkMerge [
      (mkIf (cfg.configFile != null) { "nushell/config.nu" = cfg.configFile; })
      (mkIf (cfg.envFile != null) { "nushell/env.nu" = cfg.envFile; })
    ];
  };
}
