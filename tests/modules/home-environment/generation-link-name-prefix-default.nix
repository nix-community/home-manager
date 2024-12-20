{ config, lib, ... }:

with lib;

{
  config = {
    nmt.script = ''
      assertFileExists activate
      assertFileRegex activate \
        "for p in \"\$oldProfilesDir\"/home-manager-\*; do"
    '';
  };
}
