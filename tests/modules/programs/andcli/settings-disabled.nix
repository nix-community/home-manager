{
  config,
  ...
}:
{
  programs.andcli = {
    enable = false;
    mutableSettings = true;
    package = null;
    settings.options.show_tokens = false;
  };
  xdg.configHome = "${config.home.homeDirectory}/custom-config";

  assertions = [
    {
      assertion = !(config.home.activation ? andcliMutableSettings);
      message = "andcli settings-disabled must not create mutable activation.";
    }
  ];

  nmt.script = ''
    assertPathNotExists "home-files/custom-config/andcli/config.yaml"
    assertPathNotExists "home-files/Library/Application Support/andcli/config.yaml"
  '';
}
