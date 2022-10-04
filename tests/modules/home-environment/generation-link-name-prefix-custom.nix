{ config, lib, ... }:

with lib;

{
  config = {
    home.generationLinkNamePrefix = "foobar";

    nmt.script = ''
      assertFileExists activate
      assertFileRegex activate \
        "name 'foobar-\*-link'"
    '';
  };
}
