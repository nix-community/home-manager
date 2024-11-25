{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.services.emacs;
  emacsCfg = config.programs.emacs;
  emacsBinPath = "${cfg.package}/bin";
  emacsVersion = getVersion cfg.package;

  clientWMClass =
    if versionAtLeast emacsVersion "28" then "Emacsd" else "Emacs";

  # Workaround for https://debbugs.gnu.org/47511
  needsSocketWorkaround = versionOlder emacsVersion "28"
    && cfg.socketActivation.enable;

  # Adapted from upstream emacs.desktop
  clientDesktopItem = pkgs.writeTextDir "share/applications/emacsclient.desktop"
    (generators.toINI { } {
      "Desktop Entry" = {
        Type = "Application";
        Exec = "${emacsBinPath}/emacsclient ${
            concatStringsSep " " cfg.client.arguments
          } %F";
        Terminal = false;
        Name = "Emacs Client";
        Icon = "emacs";
        Comment = "Edit text";
        GenericName = "Text Editor";
        MimeType =
          "text/english;text/plain;text/x-makefile;text/x-c++hdr;text/x-c++src;text/x-chdr;text/x-csrc;text/x-java;text/x-moc;text/x-pascal;text/x-tcl;text/x-tex;application/x-shellscript;text/x-c;text/x-c++;";
        Categories = "Development;TextEditor;";
        Keywords = "Text;Editor;";
        StartupWMClass = clientWMClass;
      };
    });

  # Match the default socket path for the Emacs version so emacsclient continues
  # to work without wrapping it.
  socketDir = "%t/emacs";
  socketPath = "${socketDir}/server";
in {
  meta.maintainers = [ maintainers.tadfisher ];

  options.services.emacs = {
    enable = mkEnableOption "the Emacs daemon";

    package = mkOption {
      type = types.package;
      default = if emacsCfg.enable then emacsCfg.finalPackage else pkgs.emacs;
      defaultText = literalExpression ''
        if config.programs.emacs.enable then config.programs.emacs.finalPackage
        else pkgs.emacs
      '';
      description = "The Emacs package to use.";
    };

    extraOptions = mkOption {
      type = with types; listOf str;
      default = [ ];
      example = [ "-f" "exwm-enable" ];
      description = ''
        Extra command-line arguments to pass to {command}`emacs`.
      '';
    };

    client = {
      enable = mkEnableOption "generation of Emacs client desktop file";
      arguments = mkOption {
        type = with types; listOf str;
        default = [ "-c" ];
        description = ''
          Command-line arguments to pass to {command}`emacsclient`.
        '';
      };
    };

    # Attrset for forward-compatibility; there may be a need to customize the
    # socket path, though allowing for such is not easy to do as systemd socket
    # units don't perform variable expansion for 'ListenStream'.
    socketActivation = {
      enable = mkEnableOption "systemd socket activation for the Emacs service";
    };

    startWithUserSession = mkOption {
      type = with types; either bool (enum [ "graphical" ]);
      default = !cfg.socketActivation.enable;
      defaultText =
        literalExpression "!config.services.emacs.socketActivation.enable";
      example = "graphical";
      description = ''
        Whether to launch Emacs service with the systemd user session. If it is
        `true`, Emacs service is started by
        `default.target`. If it is
        `"graphical"`, Emacs service is started by
        `graphical-session.target`.
      '';
    };

    defaultEditor = mkOption rec {
      type = types.bool;
      default = false;
      example = !default;
      description = ''
        Whether to configure {command}`emacsclient` as the default
        editor using the {env}`EDITOR` environment variable.
      '';
    };
  };

  config = mkIf cfg.enable (mkMerge [
    (mkIf pkgs.stdenv.isLinux {
      systemd.user.services.emacs = {
        Unit = {
          Description = "Emacs text editor";
          Documentation =
            "info:emacs man:emacs(1) https://gnu.org/software/emacs/";

          After = optional (cfg.startWithUserSession == "graphical")
            "graphical-session.target";
          PartOf = optional (cfg.startWithUserSession == "graphical")
            "graphical-session.target";

          # Avoid killing the Emacs session, which may be full of
          # unsaved buffers.
          X-RestartIfChanged = false;
        } // optionalAttrs needsSocketWorkaround {
          # Emacs deletes its socket when shutting down, which systemd doesn't
          # handle, resulting in a server without a socket.
          # See https://github.com/nix-community/home-manager/issues/2018
          RefuseManualStart = true;
        };

        Service = {
          Type = "notify";

          # We wrap ExecStart in a login shell so Emacs starts with the user's
          # environment, most importantly $PATH and $NIX_PROFILES. It may be
          # worth investigating a more targeted approach for user services to
          # import the user environment.
          ExecStart = ''
            ${pkgs.runtimeShell} -l -c "${emacsBinPath}/emacs --fg-daemon${
            # In case the user sets 'server-directory' or 'server-name' in
            # their Emacs config, we want to specify the socket path explicitly
            # so launching 'emacs.service' manually doesn't break emacsclient
            # when using socket activation.
              optionalString cfg.socketActivation.enable
              "=${escapeShellArg socketPath}"
            } ${escapeShellArgs cfg.extraOptions}"'';

          # Emacs will exit with status 15 after having received SIGTERM, which
          # is the default "KillSignal" value systemd uses to stop services.
          SuccessExitStatus = 15;

          Restart = "on-failure";
        } // optionalAttrs needsSocketWorkaround {
          # Use read-only directory permissions to prevent emacs from
          # deleting systemd's socket file before exiting.
          ExecStartPost =
            "${pkgs.coreutils}/bin/chmod --changes -w ${socketDir}";
          ExecStopPost =
            "${pkgs.coreutils}/bin/chmod --changes +w ${socketDir}";
        };
      } // optionalAttrs (cfg.startWithUserSession != false) {
        Install = {
          WantedBy = [
            (if cfg.startWithUserSession == true then
              "default.target"
            else
              "graphical-session.target")
          ];
        };
      };

      home = {
        packages = optional cfg.client.enable (hiPrio clientDesktopItem);

        sessionVariables = mkIf cfg.defaultEditor {
          EDITOR = getBin (pkgs.writeShellScript "editor" ''
            exec ${
              getBin cfg.package
            }/bin/emacsclient "''${@:---create-frame}"'');
        };
      };
    })

    (mkIf (cfg.socketActivation.enable && pkgs.stdenv.isLinux) {
      systemd.user.sockets.emacs = {
        Unit = {
          Description = "Emacs text editor";
          Documentation =
            "info:emacs man:emacs(1) https://gnu.org/software/emacs/";
        };

        Socket = {
          ListenStream = socketPath;
          FileDescriptorName = "server";
          SocketMode = "0600";
          DirectoryMode = "0700";
          # This prevents the service from immediately starting again
          # after being stopped, due to the function
          # `server-force-stop' present in `kill-emacs-hook', which
          # calls `server-running-p', which opens the socket file.
          FlushPending = true;
        };

        Install = {
          WantedBy = [ "sockets.target" ];
          # Adding this Requires= dependency ensures that systemd
          # manages the socket file, in the case where the service is
          # started when the socket is stopped.
          # The socket unit is implicitly ordered before the service.
          RequiredBy = [ "emacs.service" ];
        };
      };
    })

    (mkIf pkgs.stdenv.isDarwin {
      launchd.agents.emacs = {
        enable = true;
        config = {
          ProgramArguments = [ "${cfg.package}/bin/emacs" "--fg-daemon" ]
            ++ cfg.extraOptions;
          RunAtLoad = true;
          KeepAlive = {
            Crashed = true;
            SuccessfulExit = false;
          };
        };
      };
    })
  ]);
}
