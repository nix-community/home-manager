{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    programs.ssh = {
      enable = true;
    };

    nmt.script = ''
      assertFileExists home-files/.ssh/config
      assertFileContent home-files/.ssh/config ${./default-config-expected.conf}
    '';
  };
}
