{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    launchd.agents."test-service" = {
      enable = true;
      config = {
        ProgramArguments = [ "/some/command" "--with-arguments" "foo" ];
        KeepAlive = {
          Crashed = true;
          SuccessfulExit = false;
        };
        ProcessType = "Background";
        UnrecognizedByHomeManager = "should make it to the resulting plist";
      };
    };

    nmt.script = ''
      serviceFile=LaunchAgents/org.nix-community.home.test-service.plist
      assertFileExists $serviceFile
      assertFileContent $serviceFile ${./expected-agent.plist}
    '';
  };
}
