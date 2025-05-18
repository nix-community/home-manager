{ lib, pkgs, ... }:

{
  nixpkgs.overlays = [
    (self: super: rec {
      emacs = pkgs.writeShellScriptBin "dummy-emacs-28.2" "" // {
        outPath = "@emacs@";
      };
      emacsPackagesFor =
        _:
        lib.makeScope super.newScope (_: {
          emacsWithPackages = _: emacs;
        });
    })
  ];

  programs.emacs.enable = true;
  services.emacs.enable = true;
  services.emacs.client.enable = true;
  services.emacs.extraOptions = [
    "-f"
    "exwm-enable"
  ];
  services.emacs.startWithUserSession = "graphical";

  nmt.script = ''
    assertPathNotExists home-files/.config/systemd/user/emacs.socket
    assertFileExists home-files/.config/systemd/user/emacs.service
    assertFileExists home-path/share/applications/emacsclient.desktop

    assertFileContent \
      home-files/.config/systemd/user/emacs.service \
      ${pkgs.substitute {
        src = ./emacs-service-emacs-after-graphical-session-target.service;
        substitutions = [
          "--replace"
          "@runtimeShell@"
          pkgs.runtimeShell
        ];
      }}

    assertFileContent \
      home-path/share/applications/emacsclient.desktop \
      ${./emacs-28-emacsclient.desktop}
  '';
}
