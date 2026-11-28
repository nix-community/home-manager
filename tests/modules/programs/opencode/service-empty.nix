{
  config,
  pkgs,
  ...
}:
let
  testOpencode = import ./service-test-opencode.nix { inherit pkgs; };
in
{
  programs.opencode = {
    enable = true;
    package = testOpencode;
    service.enable = true;
  };

  assertions = [
    {
      assertion = !(config.home.activation ? opencodeServiceSettings);
      message = "An empty OpenCode service configuration must not add an activation step";
    }
  ];
}
