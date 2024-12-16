{ config, lib, ... }:

with lib;

{
  config = {
    home.pathName = "foo-bar-baz";

    nmt.script = ''
      assertFileExists activate
      assertFileRegex activate \
        "nixProfileRemove 'foo-bar-baz'"
    '';
  };
}
