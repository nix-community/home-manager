{ lib, pkgs, ... }:

{
  nixpkgs.overlays = [
    (self: super: rec {
      emacs = pkgs.writeShellScriptBin "dummy-emacs-28.0.5" "" // {
        outPath = "@emacs@";
      };
      emacsPackagesFor = _:
        lib.makeScope super.newScope (_: { emacsWithPackages = _: emacs; });
    })
  ];

  services.emacs = { enable = true; };

  nmt.script = ''
    serviceFile=LaunchAgents/org.nix-community.home.emacs.plist

    assertFileExists "$serviceFile"

    assertFileContent "$serviceFile" ${./expected-agent.plist}
  '';
}
