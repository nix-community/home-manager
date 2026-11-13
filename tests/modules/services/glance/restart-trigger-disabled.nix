{
  config,
  lib,
  pkgs,
  ...
}:

{
  services.glance.enable = true;
  xdg.configFile."glance/glance.yml".enable = false;

  assertions = [
    {
      assertion =
        config.launchd.agents.glance.enable && config.launchd.agents.glance.restartTriggers == [ ];
      message = "Glance must keep its agent without a trigger when its configuration file is disabled.";
    }
  ];

  nmt.script = ''
    assertPathNotExists home-files/.config/glance/glance.yml
  ''
  + lib.optionalString pkgs.stdenv.hostPlatform.isDarwin ''
    assertFileExists LaunchAgents/org.nix-community.home.glance.plist
    assertPathNotExists LaunchAgentRestartTriggers/org.nix-community.home.glance.json
  '';
}
