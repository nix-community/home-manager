{ config, lib, ... }:

with lib;

{
  config = {
    home.pathName = "foo-bar-baz";

    nmt.script = ''
      assertFileExists activate
      assertFileRegex activate \
        "nixProfileRemove /home/hm-user/.nix-profile 'foo-bar-baz'"
    '';
  };
}
