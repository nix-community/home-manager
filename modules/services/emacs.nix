{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.services.emacs;
  emacsCfg = config.programs.emacs;
  emacsBinPath = "${emacsCfg.finalPackage}/bin";
  # Adapted from upstream emacs.desktop
  clientDesktopItem = pkgs.makeDesktopItem rec {
    name = "emacsclient";
    desktopName = "Emacs Client";
    genericName = "Text Editor";
    comment = "Edit text";
    mimeType =
      "text/english;text/plain;text/x-makefile;text/x-c++hdr;text/x-c++src;text/x-chdr;text/x-csrc;text/x-java;text/x-moc;text/x-pascal;text/x-tcl;text/x-tex;application/x-shellscript;text/x-c;text/x-c++;";
    exec = "${emacsBinPath}/emacsclient ${
        concatStringsSep " " cfg.client.arguments
      } %F";
    icon = "emacs";
    type = "Application";
    terminal = "false";
    categories = "Utility;TextEditor;";
    extraEntries = ''
      StartupWMClass=Emacs
    '';
  };

in {
  options.services.emacs = {
    enable = mkEnableOption "the Emacs daemon";
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
  };

  config = mkIf cfg.enable {
    assertions = [{
      assertion = emacsCfg.enable;
      message = "The Emacs service module requires"
        + " 'programs.emacs.enable = true'.";
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
        ExecStart =
          "${pkgs.runtimeShell} -l -c 'exec ${emacsBinPath}/emacs --fg-daemon'";
        ExecStop = "${emacsBinPath}/emacsclient --eval '(kill-emacs)'";
        Restart = "on-failure";
      };

      Install = { WantedBy = [ "default.target" ]; };
    };

    home.packages = optional cfg.client.enable clientDesktopItem;
  };
}
