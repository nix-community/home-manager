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
      assertFileContains activate 'agentIsLoaded'
      assertFileContains activate 'if agentIsLoaded "$newDomain" "$agentName"; then'
      assertFileContains activate 'is up-to-date but not loaded'
      assertFileContains activate "printf 'gui/%s"
      assertFileContains activate "printf 'user/%s"
      assertFileContains activate 'restoreAgent "$oldSrcPath" "$dstPath" "$oldDomain" "$agentName"'
      assertFileContains activate 'bootoutAgent "$newDomain" "$agentName"'
      assertFileContains activate 'Domain does not support specified action'
      assertFileContains activate 'processAgent "$srcPath" "$dstDir" "$oldDir" "$oldDomainsDir" "$newDomainsDir" \'
      assertFileContains activate '|| launchdStatus=1'
      assertFileContains activate 'done < <(find -L "$newDir" -maxdepth 1 -name'
      assertFileContains activate 'done < <(find -L "$oldDir" -maxdepth 1 -name'
      assertFileContains activate 'if [[ "$launchdStatus" -ne 0 ]]; then'
      assertFileContains activate 'exit "$launchdStatus"'
    '';
  };
}
