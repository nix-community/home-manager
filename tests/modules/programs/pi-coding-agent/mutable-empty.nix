{
  config,
  pkgs,
  ...
}:
let
  target = "custom pi/settings.json";

in
{
  programs.pi-coding-agent = {
    package = null;
    mutableSettings = true;
    configDir = "${config.home.homeDirectory}/custom pi";
    enable = true;
    settings = { };
  };

  assertions = [
    {
      assertion = !(config.home.activation ? piCodingAgentMutableSettings);
      message = "Pi must merge only enabled, nonempty settings.";
    }
    {
      assertion = !(builtins.elem pkgs.pi-coding-agent config.home.packages);
      message = "A null Pi package must not be installed.";
    }
  ];
  nmt.script = ''
    assertPathNotExists "home-files/${target}"
  '';
}
