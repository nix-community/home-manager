{ config, pkgs, lib, ... }:

with lib;

let

  cfg = config.programs.atuin;
  daemonCfg = cfg.daemon;

  tomlFormat = pkgs.formats.toml { };

  inherit (pkgs.stdenv) isLinux isDarwin;
in {
  meta.maintainers = [ maintainers.hawkw maintainers.water-sucks ];

  options.programs.atuin = {
    enable = mkEnableOption "atuin";

    package = mkOption {
      type = types.package;
      default = pkgs.atuin;
      defaultText = literalExpression "pkgs.atuin";
      description = "The package to use for atuin.";
    };

    enableBashIntegration = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Whether to enable Atuin's Bash integration. This will bind
        `ctrl-r` to open the Atuin history.
      '';
    };

    enableZshIntegration = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Whether to enable Atuin's Zsh integration.

        If enabled, this will bind `ctrl-r` and the up-arrow
        key to open the Atuin history.
      '';
    };

    enableFishIntegration = mkOption {
      default = true;
      type = types.bool;
      description = ''
        Whether to enable Atuin's Fish integration.

        If enabled, this will bind the up-arrow key to open the Atuin history.
      '';
    };

    flags = mkOption {
      default = [ ];
      type = types.listOf types.str;
      example = [ "--disable-up-arrow" "--disable-ctrl-r" ];
      description = ''
        Flags to append to the shell hook.
      '';
    };

    settings = mkOption {
      type = with types;
        let
          prim = oneOf [ bool int str ];
          primOrPrimAttrs = either prim (attrsOf prim);
          entry = either prim (listOf primOrPrimAttrs);
          entryOrAttrsOf = t: either entry (attrsOf t);
          entries = entryOrAttrsOf (entryOrAttrsOf entry);
        in attrsOf entries // { description = "Atuin configuration"; };
      default = { };
      example = literalExpression ''
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

    enableNushellIntegration = mkOption {
      default = true;
      type = types.bool;
      description = ''
        Whether to enable Nushell integration.
      '';
    };

    daemon = {
      enable = mkEnableOption "Atuin daemon";

      logLevel = mkOption {
        default = null;
        type =
          types.nullOr (types.enum [ "trace" "debug" "info" "warn" "error" ]);
        description = ''
          Verbosity of Atuin daemon logging.
        '';
      };
    };
  };

  config = let flagsStr = escapeShellArgs cfg.flags;
  in mkIf cfg.enable (mkMerge [
    {
      # Always add the configured `atuin` package.
      home.packages = [ cfg.package ];

      # If there are user-provided settings, generate the config file.
      xdg.configFile."atuin/config.toml" = mkIf (cfg.settings != { }) {
        source = tomlFormat.generate "atuin-config" cfg.settings;
      };

      programs.bash.initExtra = mkIf cfg.enableBashIntegration ''
        if [[ :$SHELLOPTS: =~ :(vi|emacs): ]]; then
          source "${pkgs.bash-preexec}/share/bash/bash-preexec.sh"
          eval "$(${lib.getExe cfg.package} init bash ${flagsStr})"
        fi
      '';

      programs.zsh.initExtra = mkIf cfg.enableZshIntegration ''
        if [[ $options[zle] = on ]]; then
          eval "$(${lib.getExe cfg.package} init zsh ${flagsStr})"
        fi
      '';

      programs.fish.interactiveShellInit = mkIf cfg.enableFishIntegration ''
        ${lib.getExe cfg.package} init fish ${flagsStr} | source
      '';

      programs.nushell = mkIf cfg.enableNushellIntegration {
        extraEnv = ''
          let atuin_cache = "${config.xdg.cacheHome}/atuin"
          if not ($atuin_cache | path exists) {
            mkdir $atuin_cache
          }
          ${
            lib.getExe cfg.package
          } init nu ${flagsStr} | save --force ${config.xdg.cacheHome}/atuin/init.nu
        '';
        extraConfig = ''
          source ${config.xdg.cacheHome}/atuin/init.nu
        '';
      };
    }

    (mkIf daemonCfg.enable (mkMerge [
      {
        assertions = [
          {
            assertion = versionAtLeast cfg.package.version "18.2.0";
            message = ''
              The Atuin daemon requires at least version 18.2.0 or later.
            '';
          }
          {
            assertion = isLinux || isDarwin;
            message =
              "The Atuin daemon can only be configured on either Linux or macOS.";
          }
        ];

        programs.atuin.settings = { daemon = { enabled = true; }; };
      }
      (mkIf isLinux {
        programs.atuin.settings = { daemon = { systemd_socket = true; }; };

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
            Environment = lib.optionals (daemonCfg.logLevel != null)
              [ "ATUIN_LOG=${daemonCfg.logLevel}" ];
            Restart = "on-failure";
            RestartSteps = 3;
            RestartMaxDelaySec = 6;
          };
        };

        systemd.user.sockets.atuin-daemon = let
          socket_dir = if versionAtLeast cfg.package.version "18.4.0" then
            "%t"
          else
            "%D/atuin";
        in {
          Unit = { Description = "Atuin daemon socket"; };
          Install = { WantedBy = [ "sockets.target" ]; };
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
            socket_path =
              lib.mkDefault "${config.xdg.dataHome}/atuin/daemon.sock";
          };
        };

        launchd.agents.atuin-daemon = {
          enable = true;
          config = {
            ProgramArguments = [ "${lib.getExe cfg.package}" "daemon" ];
            EnvironmentVariables =
              lib.optionalAttrs (daemonCfg.logLevel != null) {
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
    ]))
  ]);
}
