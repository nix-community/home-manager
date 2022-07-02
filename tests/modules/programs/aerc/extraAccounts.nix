{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    nmt.script = let dir = "home-files/.config/aerc";
    in ''
      assertFileContent   ${dir}/accounts.conf ${./extraAccounts.expected}
      assertPathNotExists ${dir}/binds.conf
      assertPathNotExists ${dir}/aerc.conf
      assertPathNotExists ${dir}/stylesets
      assertPathNotExists ${dir}/templates
    '';

    test.stubs.aerc = { };

    programs.aerc = {
      enable = true;

      extraAccounts = {
        Test1 = {
          source = "maildir:///dev/null";
          enable-folders-sort = true;
          folders = [ "INBOX" "SENT" "JUNK" ];
        };
        Test2 = { pgp-key-id = 42; };
      };
    };
  };
}
