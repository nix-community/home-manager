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

    nmt.script = ''
      assertFileExists $home_files/.gnupg/gpg.conf
      assertFileContent $home_files/.gnupg/gpg.conf ${./override-defaults-expected.conf}
    '';
  };
}
