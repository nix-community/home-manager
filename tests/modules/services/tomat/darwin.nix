{ config, ... }:

{
  services.tomat = {
    enable = true;
    package = config.lib.test.mkStubPackage {
      name = "tomat";
      outPath = "@tomat@";
    };

    settings = {
      timer = {
        break = 10;
        work = 60;
      };
    };
  };

  nmt.script =
    let
      agentFile = "LaunchAgents/org.nix-community.home.tomat.plist";
      configFile = "home-files/Library/Application Support/tomat/config.toml";
    in
    ''
      assertFileExists "${agentFile}"
      assertFileExists "${configFile}"

      assertFileContent "$(normalizeStorePaths "${agentFile}")" ${./expected-agent.plist}
      assertFileContent "${configFile}" ${./expected-config.toml}
    '';
}
