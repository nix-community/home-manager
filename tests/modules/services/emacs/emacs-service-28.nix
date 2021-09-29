{ config, lib, pkgs, ... }:

with lib;

{
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

    nmt.script = ''
      assertPathNotExists home-files/.config/systemd/user/emacs.socket
      assertFileExists home-files/.config/systemd/user/emacs.service
      assertFileExists home-path/share/applications/emacsclient.desktop

      assertFileContent home-files/.config/systemd/user/emacs.service \
                        ${
                          pkgs.substituteAll {
                            inherit (pkgs) runtimeShell;
                            src = ./emacs-service-emacs.service;
                          }
                        }
      assertFileContent home-path/share/applications/emacsclient.desktop \
                        ${./emacs-28-emacsclient.desktop}
    '';
  };
}
