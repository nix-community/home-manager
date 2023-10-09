{ config, lib, pkgs, ... }:

let

  testScript = pkgs.writeText "test.el" ''
    ;; Emacs won't automatically load default.el when --script is specified
    (load "default")
    (let* ((test-load-config (eq hm 'home-manager))
           (test-load-package (eq (hm-test-fn) 'success))
           (is-ok (and test-load-config test-load-package)))
      (kill-emacs (if is-ok 0 1)))
  '';

  emacsBin = "${config.programs.emacs.finalPackage}/bin/emacs";

  mkTestPackage = epkgs:
    epkgs.trivialBuild {
      pname = "hm-test";
      version = "0.1.0";
      src = pkgs.writeText "hm-test.el" ''
        (defun hm-test-fn () 'success)
        (provide 'hm-test)
      '';
    };

in lib.mkIf config.test.enableBig {
  programs.emacs = {
    enable = true;
    package = pkgs.emacs-nox;
    extraConfig = ''
      (require 'hm-test)
      (setq hm 'home-manager)
    '';
    extraPackages = epkgs: [ (mkTestPackage epkgs) ];
  };

  # running emacs with --script would enable headless mode
  nmt.script = ''
    if ! ${emacsBin} --script ${testScript}; then
      fail "Failed to load default.el."
    fi
  '';
}
