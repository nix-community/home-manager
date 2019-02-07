{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.emacs;
  emacs = config.programs.emacs;
in
{
  options.services.emacs = {
    enable = mkEnableOption "Emacs daemon systemd service";
  };
  config = mkIf cfg.enable {
    systemd.user.services.emacs = {
      Unit = {
        Description = "Emacs: the extensible, self-documenting text editor";
        Documentation = "info:emacs man:emacs(1) https://gnu.org/software/emacs/";
        };

      Service = {
        Type = "simple";
        ExecStart = "${pkgs.stdenv.shell} -l -c 'exec ${emacs.finalPackage}/bin/emacs --fg-daemon'";
        ExecStop = "${emacs.finalPackage}/bin/emacsclient --eval '(kill-emacs)'";
        Restart = "on-failure";
      };

      Install = {
        WantedBy = [ "default.target" ];
      };
    };
  };
}
