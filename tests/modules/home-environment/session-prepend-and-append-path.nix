{ config, lib, pkgs, ... }:

{
  imports = [
    ({ ... }: { config.home.sessionPrependPath = [ "prefoo" ]; })
    ({ ... }: { config.home.sessionPrependPath = [ "prebar" "prebaz" ]; })
    ({ ... }: { config.home.sessionPath = [ "foo" ]; })
    ({ ... }: { config.home.sessionPath = [ "bar" "baz" ]; })
  ];

  nmt.script = ''
    hmSessVars=home-path/etc/profile.d/hm-session-vars.sh
    assertFileExists $hmSessVars
    assertFileContains $hmSessVars \
      'export PATH="prebar:prebaz:prefoo''${PATH:+:$PATH}"'
    assertFileContains $hmSessVars \
      'export PATH="$PATH''${PATH:+:}bar:baz:foo"'
  '';
}
