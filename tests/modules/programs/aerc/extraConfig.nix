{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    nmt.script = let dir = "home-files/.config/aerc";
    in ''
      assertPathNotExists ${dir}/accounts.conf
      assertPathNotExists ${dir}/binds.conf
      assertFileContent   ${dir}/aerc.conf ${./extraConfig.expected}
      assertPathNotExists ${dir}/stylesets
      assertPathNotExists ${dir}/templates
    '';

    test.stubs.aerc = { };

    programs.aerc = {
      enable = true;

      extraConfig = {
        general.unsafe-accounts-conf = true;
        ui = {
          index-format = null;
          sort = "-r date";
          spinner = [ true 2 3.4 "5" ];
          sidebar-width = 42;
          mouse-enabled = false;
          test-float = 1337.42;
        };
        "ui:account=Test" = { sidebar-width = 1337; };
      };
    };
  };
}
