{ config, pkgs, ... }:

{
  config = {
    programs.nyxt = {
      enable = true;
      extraConfig = ''
        (define-class comment-cell (nyxt/mode/repl:cell)
                      ((name "Commentary")) (:export-class-name-p t)
                      (:export-accessor-names-p t))
      '';
    };

    nmt.script = ''
      assertFileExists home-files/.config/nyxt/config.lisp
      assertFileContent home-files/.config/nyxt/config.lisp \
          ${./config.lisp}
    '';
  };
}
