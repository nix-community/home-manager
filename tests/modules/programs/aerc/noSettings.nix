{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    programs.aerc.enable = true;

    test.stubs.aerc = { };

    nmt.script = 
      let dir = "home-files/.config/aerc"; in ''
      assertPathNotExists ${dir}/accounts.conf
      assertPathNotExists ${dir}/aerc.conf
      assertPathNotExists ${dir}/binds.conf
      assertPathNotExists ${dir}/stylesets
    '';
  };
}
