{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    nmt.script = let dir = "home-files/.config/aerc";
    in ''
      assertPathNotExists ${dir}/accounts.conf
      assertPathNotExists ${dir}/aerc.conf
      assertPathNotExists ${dir}/binds.conf
      assertPathNotExists ${dir}/stylesets
    '';
    programs.aerc.enable = true;
  };
}
