{ lib, pkgs, ... }:

{
  services.emacs = {
    enable = true;
    socketActivation.enable = true;
    startWithUserSession = true;
  };

  nixpkgs.overlays = [
    (self: super: rec {
      emacs = pkgs.writeShellScriptBin "dummy-emacs-28.0.5" "" // {
        outPath = "@emacs@";
      };
      emacsPackagesFor = _:
        lib.makeScope super.newScope (_: { emacsWithPackages = _: emacs; });
    })
  ];

  nmt.script = ''
    assertFileContains \
      home-files/.config/systemd/user/emacs.service \
      "WantedBy=default.target"
  '';
}
