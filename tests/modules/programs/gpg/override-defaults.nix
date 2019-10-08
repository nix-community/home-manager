{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    programs.gpg = {
      enable = true;

      settings = {
        no-comments = false;
        s2k-cipher-algo = "AES128";
        throw-keyids = true;
      };
    };

    nixpkgs.overlays = [
      (self: super: {
        gnupg = pkgs.writeScriptBin "dummy-gnupg" "";
      })
    ];

    nmt.script = ''
      assertFileExists home-files/.gnupg/gpg.conf
      assertFileContent home-files/.gnupg/gpg.conf ${./override-defaults-expected.conf}
    '';
  };
}
