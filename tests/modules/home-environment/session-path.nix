{ config, lib, pkgs, ... }:

{
  imports = [
    ({ ... }: { config.home.sessionPath = [ "foo" ]; })
    ({ ... }: { config.home.sessionPath = [ "bar" "baz" ]; })
  ];

  nmt.script = ''
    hmSessVars=home-path/etc/profile.d/hm-session-vars.sh
    assertFileExists $hmSessVars
    assertFileContains $hmSessVars \
      'export PATH="$PATH''${PATH:+:}bar:baz:foo"'
  '';
}
