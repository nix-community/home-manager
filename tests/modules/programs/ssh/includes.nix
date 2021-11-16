{ config, lib, pkgs, ... }:

{
  config = {
    programs.ssh = {
      enable = true;
      includes = [ "config.d/*" "other/dir" ];
    };

    nmt.script = ''
      assertFileExists home-files/.ssh/config
      assertFileContains home-files/.ssh/config "Include config.d/* other/dir"
    '';
  };
}
