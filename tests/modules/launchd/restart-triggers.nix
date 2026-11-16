{
  config,
  lib,
  pkgs,
  ...
}:
let
  dependency = pkgs.writeText "launchd-trigger-dependency" "dependency";
in
{
  xdg.stateHome = "${config.home.homeDirectory}/custom state";
  # Trigger handling must not depend on the optional current-home GC root.
  home.activationGenerateGcRoot = false;
  launchd.agents = {
    triggered = {
      enable = true;
      config.Label = "custom.label";
      config.ProgramArguments = [ "/some/command" ];
      restartTriggers = [
        "alpha\nbeta"
        "quoted\"value"
      ];
    };
    context = {
      enable = true;
      config.ProgramArguments = [ "/some/command" ];
      restartTriggers = [
        dependency
        ./expected-agent.plist
        (builtins.unsafeDiscardStringContext (toString dependency))
      ];
    };
    empty = {
      enable = true;
      config.ProgramArguments = [ "/some/command" ];
    };
    disabled = {
      restartTriggers = [ "unused" ];
    };
  };

  assertions = [
    {
      assertion = builtins.hasContext (builtins.toJSON config.launchd.agents.context.restartTriggers);
      message = "Trigger identities must retain store dependency context.";
    }
    {
      assertion = lib.all builtins.isString config.launchd.agents.context.restartTriggers;
      message = "Packages and local paths must normalize to string identities.";
    }
  ];

  nmt.script = ''
    assertFileContent LaunchAgentRestartTriggers/custom.label.json ${./expected-restart-triggers.json}
    assertPathNotExists LaunchAgentRestartTriggers/org.nix-community.home.triggered.json
    assertPathNotExists LaunchAgentRestartTriggers/org.nix-community.home.empty.json
    assertPathNotExists LaunchAgentRestartTriggers/org.nix-community.home.disabled.json
    assertPathNotExists LaunchAgents/org.nix-community.home.disabled.plist
    assertFileContent LaunchAgentDomains/custom.label.domain ${builtins.toFile "expected-domain" "gui\n"}
    contextFile=$(normalizeStorePaths LaunchAgentRestartTriggers/org.nix-community.home.context.json)
    assertFileContent "$contextFile" ${./expected-restart-context.json}
    assertFileContains activate "'/home/hm-user/custom state/home-manager/launchd'"
  '';
}
