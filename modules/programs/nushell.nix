{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.nushell;

  configDir = if pkgs.stdenv.isDarwin then
    "Library/Application Support/nushell"
  else
    "${config.xdg.configHome}/nushell";

  linesOrSource = name:
    types.submodule ({ config, ... }: {
      options = {
        text = mkOption {
          type = types.lines;
          default = if config.source != null then
            builtins.readFile config.source
          else
            "";
          defaultText = literalExpression
            "if source is defined, the content of source, otherwise empty";
          description = ''
            Text of the nushell <filename>${name}</filename> file.
            If unset then the source option will be preferred.
          '';
        };

        source = mkOption {
          type = types.nullOr types.path;
          default = null;
          description = ''
            Path of the nushell <filename>${name}</filename> file to use.
            If the text option is set, it will be preferred.
          '';
        };
      };
    });

  formatNuValue = let
    indentation = "  ";
    indent = str:
      let
        lines = splitString "\n" str;
        indentedLines = map (line: "${indentation}${line}") lines;
      in lib.concatStringsSep "\n" indentedLines;
  in value:
  {
    bool = v: if v then "true" else "false";
    int = toString;
    float = toString;
    string = builtins.toJSON;
    null = v: "null";
    path = v: formatNuValue (toString v);
    list = v: ''
      [${
        lib.concatStrings (map (v: ''

          ${indent (formatNuValue v)}'') v)
      }
      ]'';
    set = v:
      if nuExpressionType.check v then
        v.__nu
      else ''
        {${
          lib.concatStrings (mapAttrsToList (k: v: ''

            ${indent "${k}: ${formatNuValue v}"}'') v)
        }
        }'';
  }.${builtins.typeOf value} value;

  nuExpressionType = mkOptionType {
    name = "nu";
    description = "Nu expression";
    check = x: isAttrs x && x ? __nu && isString x.__nu;
    merge = mergeEqualOption;
  };
in {
  meta.maintainers = [ maintainers.Philipp-M ];

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

    extraConfig = mkOption {
      type = types.lines;
      default = "";
      description = ''
        Additional configuration to add to the nushell configuration file.
      '';
    };

    extraEnv = mkOption {
      type = types.lines;
      default = "";
      description = ''
        Additional configuration to add to the nushell environment variables file.
      '';
    };

    settings = mkOption {
      type = with lib.types;
        let
          valueType = nullOr (oneOf [
            nuExpressionType
            bool
            int
            float
            str
            path
            (attrsOf valueType)
            (listOf valueType)
          ]) // {
            description = "Nu value type";
          };
        in valueType;
      default = { };
      example = literalExpression ''
        {
          show_banner = false;
          table.mode = "rounded";
          color_config.filesize.__nu = "$my_custom_color";
          completions.external.completer.__nu = '''
            {|spans|
              carapace $spans.0 nushell $spans | from json
            }
          ''';
        }
      '';
      description = ''
        Configuration options that are written to `let-env config = { ... }`.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];
    home.file = mkMerge [
      (mkIf (cfg.configFile != null || cfg.extraConfig != "") {
        "${configDir}/config.nu".text = mkMerge [
          (mkIf (cfg.settings != { }) ''
            let-env config = ${formatNuValue cfg.settings}
          '')
          (mkIf (cfg.configFile != null) cfg.configFile.text)
          cfg.extraConfig
        ];
      })
      (mkIf (cfg.envFile != null || cfg.extraEnv != "") {
        "${configDir}/env.nu".text = mkMerge [
          (mkIf (cfg.envFile != null) cfg.envFile.text)
          cfg.extraEnv
        ];
      })
    ];
  };
}
