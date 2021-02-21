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
        trusted-key = [
          "0xXXXXXXXXXXXXX"
          "0xYYYYYYYYYYYYY"
        ];
      };
    };

    nmt.script = ''
      assertFileExists home-files/.gnupg/gpg.conf
      assertFileContent home-files/.gnupg/gpg.conf ${./override-defaults-expected.conf}
    '';
  };
}
