{ config, lib, ... }:

with lib;

{
  config = {
    home.gcLinkName = "foobar";

    nmt.script = ''
      assertFileExists activate
      assertFileRegex activate \
        '-e \$gcPath/foobar'
    '';
  };
}
