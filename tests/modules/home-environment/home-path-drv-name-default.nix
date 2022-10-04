{ config, lib, ... }:

with lib;

{
  config = {
    nmt.script = ''
      assertFileExists activate
      assertFileRegex activate \
        'nix-env -i .*-home-manager-path'
    '';
  };
}
