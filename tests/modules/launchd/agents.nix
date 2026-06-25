{
  config = {
    launchd.agents."test-service" = {
      enable = true;
      config = {
        ProgramArguments = [
          "/some/command"
          "--with-arguments"
          "foo"
        ];
        KeepAlive = {
          Crashed = true;
          SuccessfulExit = false;
        };
        ProcessType = "Background";
        UnrecognizedByHomeManager = "should make it to the resulting plist";
        "\"Special\" characters" = "<should be escaped>";
      };
    };

    nmt.script = ''
      serviceFile=LaunchAgents/org.nix-community.home.test-service.plist
      assertFileExists $serviceFile
      assertFileContent $serviceFile ${./expected-agent.plist}

      domainFile=LaunchAgentDomains/org.nix-community.home.test-service.domain
      assertFileExists $domainFile
      assertFileContent $domainFile ${builtins.toFile "expected-domain" "gui\n"}

      assertFileExists activate
      assertFileContains activate 'readAgentDomain'
      assertFileContains activate 'resolveDomain'
      assertFileContains activate "printf 'gui/%s"
      assertFileContains activate "printf 'user/%s"
    '';
  };
}
