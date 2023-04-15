{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    programs.rcm = { enable = true; };

    test.stubs.rcm = { };

    nmt.script = ''
      assertPathNotExists homelfiles/.rcrc
    '';
  };
}
