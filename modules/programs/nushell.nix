{
  config,
  lib,
  osConfig,
  pkgs,
  ...
}:
let
  inherit (lib) types;
  inherit (lib.hm.nushell) isNushellInline toNushell;
  cfg = config.programs.nushell;

  systemEnvironmentPath = [
    "system"
    "build"
    "setEnvironment"
  ];
  effectiveOsConfig = if osConfig == null then { } else osConfig;
  getSystemEnvironment = lib.attrByPath systemEnvironmentPath null;
  systemEnvironmentFile = getSystemEnvironment effectiveOsConfig;
  hasSystemEnvironment = systemEnvironmentFile != null;
  sessionVariablesPackage = toString config.home.sessionVariablesPackage;
  sessionVariablesFile = "/etc/profile.d/hm-session-vars.sh";
  homeSessionVariablesFile = sessionVariablesPackage + sessionVariablesFile;
  hasSessionEnvironment =
    systemEnvironmentFile != null
    || config.home.sessionVariables != { }
    || config.home.sessionSearchVariables != { }
    || config.home.sessionVariablesExtra != "";
  hasUserEnvFile = cfg.envFile != null || cfg.extraEnv != "";
  writeEnvFile = hasSessionEnvironment || hasUserEnvFile;

  # Translate the POSIX session scripts at shell startup so references to
  # runtime values such as HOME and USER are expanded in the user environment.
  sessionVariablesLoader =
    let
      sourceSystemEnvironment = lib.optionalString hasSystemEnvironment ''
        if [ -z "''${__NIXOS_SET_ENVIRONMENT_DONE-}" ] \
          && [ -z "''${__NIX_DARWIN_SET_ENVIRONMENT_DONE-}" ]; then
          . ${lib.escapeShellArg systemEnvironmentFile} >/dev/null
        fi
      '';
      captureEnvironment = ''
        ${lib.getExe' pkgs.coreutils "env"} -0
        printf '\0'
        ${sourceSystemEnvironment}
        . ${lib.escapeShellArg homeSessionVariablesFile} >/dev/null
        ${lib.getExe' pkgs.coreutils "env"} -0
      '';
      shouldLoadSystemEnvironment = lib.optionalString hasSystemEnvironment ''
        or (
          "__NIXOS_SET_ENVIRONMENT_DONE" not-in $env
          and "__NIX_DARWIN_SET_ENVIRONMENT_DONE" not-in $env
        )
      '';
    in
    pkgs.writeText "hm-session-vars.nu" ''
      if (
        "__HM_SESS_VARS_SOURCED" not-in $env
        ${shouldLoadSystemEnvironment}
      ) {
        let captured = (
          ^${pkgs.runtimeShell} -c ${toNushell { } captureEnvironment}
          | complete
        )

        if $captured.exit_code != 0 {
          error make {
            msg: "failed to load the Home Manager session environment"
            help: $captured.stderr
          }
        }

        let separator = $"(char nul)(char nul)"
        let sections = ($captured.stdout | split row $separator)

        if ($sections | length) != 2 {
          error make {
            msg: "failed to parse the Home Manager session environment"
          }
        }

        let before = (
          $sections
          | first
          | split row (char nul)
          | compact --empty
        )
        let changed = (
          $sections
          | last
          | split row (char nul)
          | compact --empty
          | where { |entry| $entry not-in $before }
          | parse --regex '(?s)^(?<name>[^=]+)=(?<value>.*)$'
          | where { |entry| $entry.name not-in ["_" "_AST_FEATURES" "SHLVL"] }
          | transpose --header-row --as-record
        )
        let changed = if "PATH" in $changed {
          $changed | update PATH ($changed.PATH | split row (char esep))
        } else {
          $changed
        }

        load-env $changed
      }
    '';

  linesOrSource =
    name:
    types.submodule (
      { config, ... }:
      {
        options = {
          text = lib.mkOption {
            type = types.lines;
            default = if config.source != null then builtins.readFile config.source else "";
            defaultText = lib.literalExpression "if source is defined, the content of source, otherwise empty";
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
      }
    );
in
{
  meta.maintainers = with lib.maintainers; [
    joaquintrinanes
  ];

  options.programs.nushell = {
    enable = lib.mkEnableOption "nushell";

    package = lib.mkPackageOption pkgs "nushell" { nullable = true; };

    configDir = lib.mkOption {
      type = types.either types.str types.path;
      default =
        if pkgs.stdenv.isDarwin && !config.xdg.enable then
          "Library/Application Support/nushell"
        else
          "${config.xdg.configHome}/nushell";
      defaultText = lib.literalExpression ''
        if pkgs.stdenv.isDarwin && !config.xdg.enable then
          "Library/Application Support/nushell"
        else
          "''${config.xdg.configHome}/nushell";
      '';
      description = ''
        Location of the nushell config directory. This directory contains the {file}`config.nu`, {file}`env.nu`, and {file}`login.nu` files, as well as history and plugin files.
      '';
    };

    configFile = lib.mkOption {
      type = types.nullOr (linesOrSource "config.nu");
      default = null;
      example = lib.literalExpression ''
        {
          text = '''
            const NU_LIB_DIRS = $NU_LIB_DIRS ++ ''${
              lib.hm.nushell.toNushell (lib.concatStringsSep ":" [ ./scripts ])
            }
            $env.config.filesize_metric = false
            $env.config.table_mode = 'rounded'
            $env.config.use_ls_colors = true
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

    plugins = lib.mkOption {
      type = types.listOf types.package;
      default = [ ];
      example = lib.literalExpression "[ pkgs.nushellPlugins.formats ]";
      description = ''
        A list of nushell plugins to write to the plugin registry file.
      '';
    };

    settings = lib.mkOption {
      type = types.attrsOf lib.hm.types.nushellValue;
      default = { };
      example = {
        show_banner = false;
        history.format = "sqlite";
      };
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
    };

    shellAliases = lib.mkOption {
      type = types.attrsOf types.str;
      default = { };
      example = {
        ll = "ls -l";
        g = "git";
      };
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
    warnings = lib.optional (cfg.package == null && cfg.plugins != [ ]) ''
      You have configured `plugins` for `nushell` but have not set `package`.

      The listed plugins will not be installed.
    '';

    home.packages = lib.mkIf (cfg.package != null) [ cfg.package ];

    home.extraDependencies = cfg.plugins; # make sure the plugins are not garbage-collected

    home.file = lib.mkMerge [
      (
        let
          writeConfig =
            cfg.configFile != null
            || cfg.extraConfig != ""
            || aliasesStr != ""
            || cfg.settings != { }
            || cfg.environmentVariables != { };

          aliasesStr = lib.concatLines (
            lib.mapAttrsToList (k: v: "alias ${toNushell { } k} = ${v}") cfg.shellAliases
          );
        in
        lib.mkIf writeConfig {
          "${cfg.configDir}/config.nu".text = lib.mkMerge [
            (
              let
                hasEnvVars = cfg.environmentVariables != { };
                envVarsStr = ''
                  load-env ${toNushell { } cfg.environmentVariables}
                '';
              in
              lib.mkIf hasEnvVars envVarsStr
            )
            (
              let
                flattenSettings =
                  let
                    joinDot = a: b: "${if a == "" then "" else "${a}."}${b}";
                    unravel =
                      prefix: value:
                      if lib.isAttrs value && !isNushellInline value then
                        lib.concatMap (key: unravel (joinDot prefix key) value.${key}) (builtins.attrNames value)
                      else
                        [ (lib.nameValuePair prefix value) ];
                  in
                  unravel "";
                mkLine =
                  { name, value }:
                  ''
                    $env.config.${name} = ${toNushell { } value}
                  '';
                settingsLines = lib.concatMapStrings mkLine (flattenSettings cfg.settings);

              in
              lib.mkIf (cfg.settings != { }) settingsLines
            )
            (lib.mkIf (cfg.configFile != null) cfg.configFile.text)
            cfg.extraConfig
            aliasesStr
          ];
        }
      )

      (lib.mkIf writeEnvFile {
        "${cfg.configDir}/env.nu".text = lib.mkMerge [
          (lib.mkIf hasSessionEnvironment "source ${sessionVariablesLoader}")
          (lib.mkIf (cfg.envFile != null) cfg.envFile.text)
          cfg.extraEnv
        ];
      })
      (lib.mkIf (cfg.loginFile != null || cfg.extraLogin != "") {
        "${cfg.configDir}/login.nu".text = lib.mkMerge [
          (lib.mkIf (cfg.loginFile != null) cfg.loginFile.text)
          cfg.extraLogin
        ];
      })

      (
        let
          msgPackz = pkgs.runCommand "nushellMsgPackz" { } ''
            mkdir -p "$out"
            ${lib.getExe cfg.package} \
              --plugin-config "$out/plugin.msgpackz" \
              --commands '${
                lib.concatStringsSep "; " (map (plugin: "plugin add ${lib.getExe plugin}") cfg.plugins)
              }'
          '';
        in
        lib.mkIf ((cfg.package != null) && (cfg.plugins != [ ])) {
          "${cfg.configDir}/plugin.msgpackz".source = "${msgPackz}/plugin.msgpackz";
        }
      )
    ];
  };
}
