{ config, lib, pkgs, ... }:
let
  inherit (lib) types;
  inherit (lib.hm.nushell) isNushellInline toNushell;
  cfg = config.programs.nushell;

  configDir = if pkgs.stdenv.isDarwin && !config.xdg.enable then
    "Library/Application Support/nushell"
  else
    "${config.xdg.configHome}/nushell";

  linesOrSource = name:
    types.submodule ({ config, ... }: {
      options = {
        text = lib.mkOption {
          type = types.lines;
          default = if config.source != null then
            builtins.readFile config.source
          else
            "";
          defaultText = lib.literalExpression
            "if source is defined, the content of source, otherwise empty";
          description = ''
            Text of the nushell {file}`${name}` file.
            If unset then the source option will be preferred.
          '';
        };

        source = lib.mkOption {
          type = types.nullOr types.path;
          default = null;
          description = ''
            Path of the nushell {file}`${name}` file to use.
            If the text option is set, it will be preferred.
          '';
        };
      };
    });
in {
  meta.maintainers =
    [ lib.maintainers.Philipp-M lib.maintainers.joaquintrinanes ];

  options.programs.nushell = {
    enable = lib.mkEnableOption "nushell";

    package = lib.mkPackageOption pkgs "nushell" { };

    configFile = lib.mkOption {
      type = types.nullOr (linesOrSource "config.nu");
      default = null;
      example = lib.literalExpression ''
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

        See <https://www.nushell.sh/book/configuration.html#configuration> for more information.
      '';
    };

    envFile = lib.mkOption {
      type = types.nullOr (linesOrSource "env.nu");
      default = null;
      example = ''
        $env.FOO = 'BAR'
      '';
      description = ''
        The environment variables file to be used for nushell.

        See <https://www.nushell.sh/book/configuration.html#configuration> for more information.
      '';
    };

    loginFile = lib.mkOption {
      type = types.nullOr (linesOrSource "login.nu");
      default = null;
      example = ''
        # Prints "Hello, World" upon logging into tty1
        if (tty) == "/dev/tty1" {
          echo "Hello, World"
        }
      '';
      description = ''
        The login file to be used for nushell upon logging in.

        See <https://www.nushell.sh/book/configuration.html#configuring-nu-as-a-login-shell> for more information.
      '';
    };

    extraConfig = lib.mkOption {
      type = types.lines;
      default = "";
      description = ''
        Additional configuration to add to the nushell configuration file.
      '';
    };

    extraEnv = lib.mkOption {
      type = types.lines;
      default = "";
      description = ''
        Additional configuration to add to the nushell environment variables file.
      '';
    };

    extraLogin = lib.mkOption {
      type = types.lines;
      default = "";
      description = ''
        Additional configuration to add to the nushell login file.
      '';
    };

    settings = lib.mkOption {
      type = types.attrsOf lib.hm.types.nushellValue;
      default = { };
      description = ''
        Nushell settings. These will be flattened and assigned one by one to `$env.config` to avoid overwriting the default or existing options.

        For example:
        ```nix
        {
          show_banner = false;
          completions.external = {
            enable = true;
            max_results = 200;
          };
        }
        ```
        becomes:
        ```nushell
        $env.config.completions.external.enable = true
        $env.config.completions.external.max_results = 200
        $env.config.show_banner = false
        ```
      '';
      example = {
        show_banner = false;
        history.format = "sqlite";
      };
    };

    shellAliases = lib.mkOption {
      type = types.attrsOf types.str;
      default = { };
      example = { ll = "ls -l"; };
      description = ''
        An attribute set that maps aliases (the top level attribute names in
        this option) to command strings or directly to build outputs.
      '';
    };

    environmentVariables = lib.mkOption {
      type = types.attrsOf lib.hm.types.nushellValue;
      default = { };
      example = lib.literalExpression ''
        {
          FOO = "BAR";
          LIST_VALUE = [ "foo" "bar" ];
          NU_LIB_DIRS = lib.concatStringsSep ":" [ ./scripts ];
          PROMPT_COMMAND = lib.hm.nushell.mkNushellInline '''{|| "> "}''';
          ENV_CONVERSIONS.PATH = {
            from_string = lib.hm.nushell.mkNushellInline "{|s| $s | split row (char esep) }";
            to_string = lib.hm.nushell.mkNushellInline "{|v| $v | str join (char esep) }";
          };
        }
      '';
      description = ''
        Environment variables to be set.

        Inline values can be set with `lib.hm.nushell.mkNushellInline`.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];

    home.file = lib.mkMerge [
      (let
        writeConfig = cfg.configFile != null || cfg.extraConfig != ""
          || aliasesStr != "" || cfg.settings != { };

        aliasesStr = lib.concatLines
          (lib.mapAttrsToList (k: v: "alias ${k} = ${v}") cfg.shellAliases);
      in lib.mkIf writeConfig {
        "${configDir}/config.nu".text = lib.mkMerge [
          (lib.mkIf (cfg.configFile != null) cfg.configFile.text)
          (let
            flattenSettings = settings:
              let
                unravel = prefixes: value:
                  if (lib.isAttrs value && !isNushellInline value) then
                    lib.flatten
                    (map (key: unravel (prefixes ++ [ key ]) value.${key})
                      (builtins.attrNames value))
                  else
                    lib.nameValuePair (lib.concatStringsSep "." prefixes) value;
              in lib.listToAttrs (unravel [ ] settings);

            flattenedSettings = flattenSettings cfg.settings;
          in lib.mkIf (cfg.settings != { }) (lib.concatLines (lib.mapAttrsToList
            (key: value: "$env.config.${key} = ${toNushell { } value}")
            flattenedSettings)))
          cfg.extraConfig
          aliasesStr
        ];
      })

      (let
        hasEnvVars = cfg.environmentVariables != { };
        envVarsStr = ''
          load-env ${toNushell { } cfg.environmentVariables}
        '';
      in lib.mkIf (cfg.envFile != null || cfg.extraEnv != "" || hasEnvVars) {
        "${configDir}/env.nu".text = lib.mkMerge [
          (lib.mkIf (cfg.envFile != null) cfg.envFile.text)
          cfg.extraEnv
          envVarsStr
        ];
      })
      (lib.mkIf (cfg.loginFile != null || cfg.extraLogin != "") {
        "${configDir}/login.nu".text = lib.mkMerge [
          (lib.mkIf (cfg.loginFile != null) cfg.loginFile.text)
          cfg.extraLogin
        ];
      })
    ];
  };
}
