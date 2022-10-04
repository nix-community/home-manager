{ config, lib, ... }:

with lib;

{
  config = {
    home.pathName = "foo-bar-baz";

    nmt.script = ''
      assertFileExists activate
      assertFileRegex activate \
        'nix-env -i .*-foo-bar-baz'
    '';
  };
}
