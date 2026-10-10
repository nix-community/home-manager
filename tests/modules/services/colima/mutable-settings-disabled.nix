{
  config,
  lib,
  ...
}:
let
  cfg = config.services.colima;

in
{
  home.stateVersion = lib.mkForce "26.05";
  xdg.enable = false;
  xdg.configHome = "${config.home.homeDirectory}/custom-config";
  services.colima = {
    enable = false;
    profiles = lib.mkForce {
      writable = {
        mutableSettings = true;
        isService = true;
        settings = {
          cpu = 4;
          env.TEST_TOKEN = "test-only";
        };
      };
      immutable = {
        settings.memory = 2;
      };
      empty = {
        mutableSettings = true;
      };
    };
  };
  assertions = [
    {
      assertion = !(config.home.activation ? colima-writableMutableSettings);
      message = "Colima mutable activation must follow enable.";
    }
    {
      assertion = !(config.home.activation ? colima-emptyMutableSettings);
      message = "Empty Colima profiles must not create mutable activation.";
    }
    {
      assertion = !cfg.profiles.immutable.mutableSettings;
      message = "Colima profiles must remain immutable by default.";
    }
    {
      assertion = cfg.colimaHomeDir == ".colima";
      message = "Colima home must honor state version, XDG, and custom paths.";
    }
  ];
  nmt.script = ''
    assertPathNotExists "home-files/.colima/immutable/colima.yaml"
    assertPathNotExists "home-files/.colima/writable/colima.yaml"
    assertPathNotExists "home-files/.colima/empty/colima.yaml"
  '';
}
