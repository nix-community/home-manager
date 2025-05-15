{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.programs.atuin;
  daemonCfg = cfg.daemon;

  tomlFormat = pkgs.formats.toml { };

  inherit (lib) mkIf mkOption types;
  inherit (pkgs.stdenv) isLinux isDarwin;
in
{
  meta.maintainers = with lib.maintainers; [
    hawkw
    water-sucks
  ];

  options.programs.atuin = {
    enable = lib.mkEnableOption "atuin";

    package = lib.mkPackageOption pkgs "atuin" { };

    enableBashIntegration = lib.hm.shell.mkBashIntegrationOption {
      inherit config;
      extraDescription = "If enabled, this will bind `ctrl-r` to open the Atuin history.";
    };

    enableFishIntegration = lib.hm.shell.mkFishIntegrationOption {
      inherit config;
      extraDescription = "If enabled, this will bind the up-arrow key to open the Atuin history.";
    };

    enableNushellIntegration = lib.hm.shell.mkNushellIntegrationOption { inherit config; };

    enableZshIntegration = lib.hm.shell.mkZshIntegrationOption {
      inherit config;
      extraDescription = ''
        If enabled, this will bind `ctrl-r` and the up-arrow key to open the
        Atuin history.
      '';
    };

    flags = mkOption {
      default = [ ];
      type = types.listOf types.str;
      example = [
        "--disable-up-arrow"
        "--disable-ctrl-r"
      ];
      description = ''
        Flags to append to the shell hook.
      '';
    };

    settings = mkOption {
      type =
        with types;
        let
          prim = oneOf [
            bool
            int
            str
          ];
          primOrPrimAttrs = either prim (attrsOf prim);
          entry = either prim (listOf primOrPrimAttrs);
          entryOrAttrsOf = t: either entry (attrsOf t);
          entries = entryOrAttrsOf (entryOrAttrsOf entry);
        in
        attrsOf entries // { description = "Atuin configuration"; };
      default = { };
      example = lib.literalExpression ''
        {
          auto_sync = true;
          sync_frequency = "5m";
          sync_address = "https://api.atuin.sh";
          search_mode = "prefix";
        }
      '';
      description = ''
        Configuration written to
        {file}`$XDG_CONFIG_HOME/atuin/config.toml`.

        See <https://atuin.sh/docs/config/> for the full list
        of options.
      '';
    };

    themes = mkOption {
      type = types.attrsOf (
        types.oneOf [
          tomlFormat.type
          types.path
          types.lines
        ]
      );
      description = ''
        Each theme is written to
        {file}`$XDG_CONFIG_HOME/atuin/themes/theme-name.toml`
        where the name of each attribute is the theme-name

        See <https://atuin.sh/guide/theming/> for the full list
        of options.
      '';
      default = { };
      example = lib.literalExpression ''
        {
          "my-theme" = {
            theme.name = "My Theme";
            colors = {
              Base = "#000000";
              Title = "#FFFFFF";
            };
          };
        }
      '';
    };

    daemon = {
      enable = lib.mkEnableOption "Atuin daemon";

      logLevel = mkOption {
        default = null;
        type = types.nullOr (
          types.enum [
            "trace"
            "debug"
            "info"
            "warn"
            "error"
          ]
        );
        description = ''
          Verbosity of Atuin daemon logging.
        '';
      };
    };
  };

  config =
    let
      flagsStr = lib.escapeShellArgs cfg.flags;
    in
    mkIf cfg.enable (
      lib.mkMerge [
        {
          # Always add the configured `atuin` package.
          home.packages = [ cfg.package ];

          # If there are user-provided settings, generate the config file.
          xdg.configFile = lib.mkMerge [
            (mkIf (cfg.settings != { }) {
              "atuin/config.toml" = {
                source = tomlFormat.generate "atuin-config" cfg.settings;
              };
            })

            (mkIf (cfg.themes != { }) (
              lib.mapAttrs' (
                name: theme:
                lib.nameValuePair "atuin/themes/${name}.toml" {
                  source =
                    if lib.isString theme then
                      pkgs.writeText "atuin-theme-${name}" theme
                    else if builtins.isPath theme || lib.isStorePath theme then
                      theme
                    else
                      tomlFormat.generate "atuin-theme-${name}" theme;
                }
              ) cfg.themes
            ))
          ];

          programs.bash.initExtra = mkIf cfg.enableBashIntegration ''
            if [[ :$SHELLOPTS: =~ :(vi|emacs): ]]; then
              source "${pkgs.bash-preexec}/share/bash/bash-preexec.sh"
              eval "$(${lib.getExe cfg.package} init bash ${flagsStr})"
            fi
          '';

          programs.zsh.initContent = mkIf cfg.enableZshIntegration ''
            if [[ $options[zle] = on ]]; then
              eval "$(${lib.getExe cfg.package} init zsh ${flagsStr})"
            fi
          '';

          programs.fish.interactiveShellInit = mkIf cfg.enableFishIntegration ''
            ${lib.getExe cfg.package} init fish ${flagsStr} | source
          '';

          programs.nushell = mkIf cfg.enableNushellIntegration {
            extraConfig = ''
              source ${
                pkgs.runCommand "atuin-nushell-config.nu"
                  {
                    nativeBuildInputs = [ pkgs.writableTmpDirAsHomeHook ];
                  }
                  ''
                    ${lib.getExe cfg.package} init nu ${flagsStr} >> "$out"
                  ''
              }
            '';
          };
        }

        (mkIf daemonCfg.enable (
          lib.mkMerge [
            {
              assertions = [
                {
                  assertion = lib.versionAtLeast cfg.package.version "18.2.0";
                  message = ''
                    The Atuin daemon requires at least version 18.2.0 or later.
                  '';
                }
                {
                  assertion = isLinux || isDarwin;
                  message = "The Atuin daemon can only be configured on either Linux or macOS.";
                }
              ];

              programs.atuin.settings = {
                daemon = {
                  enabled = true;
                };
              };
            }
            (mkIf isLinux {
              programs.atuin.settings = {
                daemon = {
                  systemd_socket = true;
                };
              };

              systemd.user.services.atuin-daemon = {
                Unit = {
                  Description = "Atuin daemon";
                  Requires = [ "atuin-daemon.socket" ];
                };
                Install = {
                  Also = [ "atuin-daemon.socket" ];
                  WantedBy = [ "default.target" ];
                };
                Service = {
                  ExecStart = "${lib.getExe cfg.package} daemon";
                  Environment = lib.optionals (daemonCfg.logLevel != null) [ "ATUIN_LOG=${daemonCfg.logLevel}" ];
                  Restart = "on-failure";
                  RestartSteps = 3;
                  RestartMaxDelaySec = 6;
                };
              };

              systemd.user.sockets.atuin-daemon =
                let
                  socket_dir = if lib.versionAtLeast cfg.package.version "18.4.0" then "%t" else "%D/atuin";
                in
                {
                  Unit = {
                    Description = "Atuin daemon socket";
                  };
                  Install = {
                    WantedBy = [ "sockets.target" ];
                  };
                  Socket = {
                    ListenStream = "${socket_dir}/atuin.sock";
                    SocketMode = "0600";
                    RemoveOnStop = true;
                  };
                };
            })
            (mkIf isDarwin {
              programs.atuin.settings = {
                daemon = {
                  socket_path = lib.mkDefault "${config.xdg.dataHome}/atuin/daemon.sock";
                };
              };

              launchd.agents.atuin-daemon = {
                enable = true;
                config = {
                  ProgramArguments = [
                    "${lib.getExe cfg.package}"
                    "daemon"
                  ];
                  EnvironmentVariables = lib.optionalAttrs (daemonCfg.logLevel != null) {
                    ATUIN_LOG = daemonCfg.logLevel;
                  };
                  KeepAlive = {
                    Crashed = true;
                    SuccessfulExit = false;
                  };
                  ProcessType = "Background";
                };
              };
            })
          ]
        ))
      ]
    );
}
