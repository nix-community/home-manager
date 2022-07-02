{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    nmt.script = let dir = "home-files/.config/aerc";
    in ''
      assertPathNotExists ${dir}/accounts.conf
      assertPathNotExists ${dir}/binds.conf
      assertPathNotExists ${dir}/aerc.conf
      assertPathNotExists ${dir}/stylesets
      assertFileContent   ${dir}/templates/new_mail   ${./templates.expected}
      assertFileContent   ${dir}/templates/other_mail ${./templates.expected}
    '';

    test.stubs.aerc = { };

    programs.aerc = {
      enable = true;
      templates = rec {
        new_mail = ''
          X-Mailer: aerc {{version}}

          Just a test.
        '';
        other_mail = new_mail;
      };
    };
  };
}
