{
  config,
  lib,
  pkgs,
  ...
}:
let
  testOpencode = import ./service-test-opencode.nix { inherit pkgs; };
in
{
  home.homeDirectory = lib.mkForce "/@TMPDIR@/hm-user";

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

  nmt.script = ''
    export HOME=$TMPDIR/hm-user
    export XDG_CONFIG_HOME=$HOME/.config
    assertPathNotExists "$HOME/.config/opencode/service.json"
  '';
}
