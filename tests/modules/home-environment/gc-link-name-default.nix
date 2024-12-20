{ config, lib, ... }:

with lib;

{
  config = {
    nmt.script = ''
      assertFileExists activate
      assertFileRegex activate \
        '\$hmGcrootsDir/current-home'
    '';
  };
}
