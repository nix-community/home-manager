{ config, lib, ... }:

with lib;

{
  config = {
    nmt.script = ''
      assertFileExists activate
      assertFileRegex activate \
        "nixProfileRemove 'home-manager-path'"
    '';
  };
}
