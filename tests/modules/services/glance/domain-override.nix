{ lib, pkgs, ... }:

{
  services.glance.enable = true;
  launchd.agents.glance.domain = "gui";

  nmt.script = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin ''
    domainFile=LaunchAgentDomains/org.nix-community.home.glance.domain
    assertFileExists "$domainFile"
    assertFileContent "$domainFile" ${builtins.toFile "expected-domain" "gui\n"}
    assertFileContains activate 'domain="gui/$(id -u)"'
    assertFileContains activate 'launchctl kickstart -k "$domain/org.nix-community.home.glance"'
  '';
}
