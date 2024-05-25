{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.nushell;

  configDir = if pkgs.stdenv.isDarwin && !config.xdg.enable then
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
            Text of the nushell {file}`${name}` file.
            If unset then the source option will be preferred.
          '';
        };

        source = mkOption {
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

        See <https://www.nushell.sh/book/configuration.html#configuration> for more information.
      '';
    };

    envFile = mkOption {
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

    loginFile = mkOption {
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

    extraLogin = mkOption {
      type = types.lines;
      default = "";
      description = ''
        Additional configuration to add to the nushell login file.
      '';
    };

    shellAliases = mkOption {
      type = types.attrsOf types.str;
      default = { };
      example = { ll = "ls -l"; };
      description = ''
        An attribute set that maps aliases (the top level attribute names in
        this option) to command strings or directly to build outputs.
      '';
    };

    environmentVariables = mkOption {
      type = types.attrsOf types.str;
      default = { };
      example = { FOO = "BAR"; };
      description = ''
        An attribute set that maps an environment variable to a shell interpreted string.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    home.file = mkMerge [
      (let
        writeConfig = cfg.configFile != null || cfg.extraConfig != ""
          || aliasesStr != "";

        aliasesStr = concatStringsSep "\n"
          (mapAttrsToList (k: v: "alias ${k} = ${v}") cfg.shellAliases);
      in mkIf writeConfig {
        "${configDir}/config.nu".text = mkMerge [
          (mkIf (cfg.configFile != null) cfg.configFile.text)
          cfg.extraConfig
          aliasesStr
        ];
      })

      (let
        envVarsStr = concatStringsSep "\n"
          (mapAttrsToList (k: v: "$env.${k} = ${v}") cfg.environmentVariables);
      in mkIf (cfg.envFile != null || cfg.extraEnv != "" || envVarsStr != "") {
        "${configDir}/env.nu".text = mkMerge [
          (mkIf (cfg.envFile != null) cfg.envFile.text)
          cfg.extraEnv
          envVarsStr
        ];
      })
      (mkIf (cfg.loginFile != null || cfg.extraLogin != "") {
        "${configDir}/login.nu".text = mkMerge [
          (mkIf (cfg.loginFile != null) cfg.loginFile.text)
          cfg.extraLogin
        ];
      })
    ];
  };
}
