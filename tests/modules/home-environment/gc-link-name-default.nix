{ config, lib, ... }:

with lib;

{
  config = {
    nmt.script = ''
      assertFileExists activate
      assertFileRegex activate \
        '-e \$gcPath/current-home'
    '';
  };
}
