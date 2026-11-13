{
  config,
  ...
}:
{
  programs.pi-coding-agent = {
    enable = true;
    package = null;
    configDir = "${config.home.homeDirectory}/custom pi";
    settings.theme = "dark";
  };
  assertions = [
    {
      assertion = !config.programs.pi-coding-agent.mutableSettings;
      message = "pi-coding-agent: The configured settings ownership mode must be preserved.";
    }
    {
      assertion = !(config.home.activation ? piCodingAgentMutableSettings);
      message = "pi-coding-agent: The selected configuration must schedule only its expected settings activation entries.";
    }
  ];

  nmt.script = ''
    assertFileRegex home-path/etc/profile.d/hm-session-vars.sh \
      'PI_CODING_AGENT_DIR'
    assertFileExists "home-files/custom pi/settings.json"
    assertFileContent "home-files/custom pi/settings.json" ${./custom-config-dir-expected.json}
  '';
}
