{ config, lib, pkgs, ... }:

with lib;

let

in {
  config = {
    nixpkgs.overlays = [
      (self: super: rec {
        emacs = pkgs.writeShellScriptBin "dummy-emacs-28.0.5" "" // {
          outPath = "@emacs@";
        };
        emacsPackagesFor = _:
          makeScope super.newScope (_: { emacsWithPackages = _: emacs; });
      })
    ];

    programs.emacs.enable = true;
    services.emacs.enable = true;
    services.emacs.client.enable = true;
    services.emacs.extraOptions = [ "-f" "exwm-enable" ];
    services.emacs.socketActivation.enable = true;

    nmt.script = ''
      assertFileExists home-files/.config/systemd/user/emacs.socket
      assertFileExists home-files/.config/systemd/user/emacs.service
      assertFileExists home-path/share/applications/emacsclient.desktop

      assertFileContent home-files/.config/systemd/user/emacs.socket \
                        ${./emacs-socket-emacs.socket}
      assertFileContent home-files/.config/systemd/user/emacs.service \
                        ${
                          pkgs.substituteAll {
                            inherit (pkgs) runtimeShell coreutils;
                            src = ./emacs-socket-emacs.service;
                          }
                        }
      assertFileContent home-path/share/applications/emacsclient.desktop \
                        ${./emacs-28-emacsclient.desktop}
    '';
  };
}
