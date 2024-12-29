{ config, lib, ... }:

with lib;

{
  config = {
    nmt.script = ''
      assertFileExists activate
      assertFileRegex activate \
        "nixProfileRemove /home/hm-user/.nix-profile 'home-manager-path'"
    '';
  };
}
