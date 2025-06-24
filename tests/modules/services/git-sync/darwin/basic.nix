{ config, ... }:

{
  services.git-sync = {
    enable = true;
    package = config.lib.test.mkStubPackage { outPath = "@git-sync@"; };
    repositories.test = {
      path = "/a/path";
      uri = "git+ssh://user@example.com:/~user/path/to/repo.git";
    };
  };

  nmt.script = ''
    serviceFile=LaunchAgents/org.nix-community.home.git-sync-test.plist
    assertFileExists "$serviceFile"
    assertFileContent "$serviceFile" ${./expected-agent.plist}
  '';
}
