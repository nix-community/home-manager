{
  config,
  lib,
  pkgs,
  ...
}:

{
  services.glance.enable = true;

  # Move the module's file away and link a local file where Glance reads its
  # configuration instead.
  xdg.configFile."glance/glance.yml".target = "glance/unused.yml";
  home.file.glance-local = {
    target = ".config/glance/glance.yml";
    source = toString ./glance-example-config.yml;
  };

  assertions = [
    {
      assertion =
        let
          triggers = config.launchd.agents.glance.restartTriggers;
        in
        builtins.length triggers == 1
        && builtins.hasContext (builtins.head triggers)
        && lib.hasSuffix "-hm_glanceexampleconfig.yml" (builtins.head triggers);
      message = "Glance must restart only for the file linked at its configuration path.";
    }
  ];

  nmt.script = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin ''
    triggersFile=LaunchAgentRestartTriggers/org.nix-community.home.glance.json
    triggersFile=$(normalizeStorePaths $triggersFile)
    assertFileContent "$triggersFile" ${./glance-restart-triggers-overrides.json}
  '';
}
