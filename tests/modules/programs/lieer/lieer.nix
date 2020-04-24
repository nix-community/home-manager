{ config, lib, pkgs, ... }:

with lib;

{
  imports = [ ../../accounts/email-test-accounts.nix ];

  config = {
    programs.lieer.enable = true;

    accounts.email.accounts = { "hm@example.com".lieer.enable = true; };

    nixpkgs.overlays = [
      (self: super: { gmailieer = pkgs.writeScriptBin "dummy-gmailieer" ""; })
    ];

    nmt.script = ''
      assertFileExists home-files/Mail/hm@example.com/.gmailieer.json
      assertFileContent home-files/Mail/hm@example.com/.gmailieer.json \
                        ${./lieer-expected.json}
    '';
  };
}
