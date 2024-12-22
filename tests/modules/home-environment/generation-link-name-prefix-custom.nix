{ config, lib, ... }:

with lib;

{
  config = {
    home.generationLinkNamePrefix = "foobar";

    nmt.script = ''
      assertFileExists activate
      assertFileRegex activate \
        "for p in \"\$oldProfilesDir\"/foobar-\*; do"
      !assertFileRegex activate \
        "for p in \"\$oldProfilesDir\"/foobar-\*; do"
      assertFileRegex activate \
        "genProfilePath=\"\$profilesDir/foobar\""
    '';
  };
}
