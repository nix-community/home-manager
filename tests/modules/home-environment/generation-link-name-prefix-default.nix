{ config, lib, ... }:

with lib;

{
  config = {
    nmt.script = ''
      assertFileExists activate
      assertFileRegex activate \
        "name 'home-manager-\*-link'"
    '';
  };
}
