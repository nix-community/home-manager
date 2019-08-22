{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.services.emacs;
  emacsCfg = config.programs.emacs;
  emacsBinPath = "${emacsCfg.finalPackage}/bin";

in

{
  options.services.emacs = {
    enable = mkEnableOption "the Emacs daemon";
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = emacsCfg.enable;
        message = "The Emacs service module requires"
          + " 'programs.emacs.enable = true'.";
      }
    ];

    systemd.user.services.emacs = {
      Unit = {
        Description = "Emacs: the extensible, self-documenting text editor";
        Documentation = "info:emacs man:emacs(1) https://gnu.org/software/emacs/";

        # Avoid killing the Emacs session, which may be full of
        # unsaved buffers.
        X-RestartIfChanged = false;
      };

      Service = {
        ExecStart = "${pkgs.runtimeShell} -l -c 'exec ${emacsBinPath}/emacs --fg-daemon'";
        ExecStop = "${emacsBinPath}/emacsclient --eval '(kill-emacs)'";
        Restart = "on-failure";
      };

      Install = {
        WantedBy = [ "default.target" ];
      };
    };
  };
}
