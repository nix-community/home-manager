{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.services.emacs;
  emacsCfg = config.programs.emacs;
  emacsBinPath = "${cfg.package}/bin";
  emacsVersion = getVersion cfg.package;

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
        Categories = "Utility;TextEditor;";
        StartupWMClass = "Emacs";
      };
    });

  # Match the default socket path for the Emacs version so emacsclient continues
  # to work without wrapping it. It might be worthwhile to allow customizing the
  # socket path, but we would want to wrap emacsclient in the user profile to
  # connect to the alternative socket by default for Emacs 26, and set
  # EMACS_SOCKET_NAME for Emacs 27.
  #
  # As systemd doesn't perform variable expansion for the ListenStream param, we
  # would also have to solve the problem of matching the shell path to the path
  # used in the socket unit, which would likely involve templating. It seems of
  # little value for the most common use case of one Emacs daemon per user
  # session.
  socketPath = if versionAtLeast emacsVersion "27" then
    "%t/emacs/server"
  else
    "%T/emacs%U/server";

in {
  meta.maintainers = [ maintainers.tadfisher ];

  options.services.emacs = {
    enable = mkEnableOption "the Emacs daemon";

    package = mkOption {
      type = types.package;
      default = if emacsCfg.enable then emacsCfg.finalPackage else pkgs.emacs;
      defaultText = literalExample ''
        if config.programs.emacs.enable then config.programs.emacs.finalPackage
        else pkgs.emacs
      '';
      description = "The Emacs package to use.";
    };

    client = {
      enable = mkEnableOption "generation of Emacs client desktop file";
      arguments = mkOption {
        type = with types; listOf str;
        default = [ "-c" ];
        description = ''
          Command-line arguments to pass to <command>emacsclient</command>.
        '';
      };
    };

    # Attrset for forward-compatibility; there may be a need to customize the
    # socket path, though allowing for such is not easy to do as systemd socket
    # units don't perform variable expansion for 'ListenStream'.
    socketActivation = {
      enable = mkEnableOption "systemd socket activation for the Emacs service";
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      assertions = [{
        assertion = cfg.socketActivation.enable
          -> versionAtLeast emacsVersion "26";
        message = "Socket activation requires Emacs 26 or newer.";
      }];

      systemd.user.services.emacs = {
        Unit = {
          Description = "Emacs: the extensible, self-documenting text editor";
          Documentation =
            "info:emacs man:emacs(1) https://gnu.org/software/emacs/";

          # Avoid killing the Emacs session, which may be full of
          # unsaved buffers.
          X-RestartIfChanged = false;
        };

        Service = {
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
            }"'';
          # We use '(kill-emacs 0)' to avoid exiting with a failure code, which
          # would restart the service immediately.
          ExecStop = "${emacsBinPath}/emacsclient --eval '(kill-emacs 0)'";
          Restart = "on-failure";
        };
      } // optionalAttrs (!cfg.socketActivation.enable) {
        Install = { WantedBy = [ "default.target" ]; };
      };

      home.packages = optional cfg.client.enable (hiPrio clientDesktopItem);
    }

    (mkIf cfg.socketActivation.enable {
      systemd.user.sockets.emacs = {
        Unit = {
          Description = "Emacs: the extensible, self-documenting text editor";
          Documentation =
            "info:emacs man:emacs(1) https://gnu.org/software/emacs/";
        };

        Socket = {
          ListenStream = socketPath;
          FileDescriptorName = "server";
          SocketMode = "0600";
          DirectoryMode = "0700";
        };

        Install = { WantedBy = [ "sockets.target" ]; };
      };
    })
  ]);
}
