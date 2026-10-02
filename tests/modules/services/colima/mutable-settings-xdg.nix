{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.colima;
  activation = config.home.activation.colima-writableMutableSettings;
in
{
  home.stateVersion = lib.mkForce "26.05";
  xdg.enable = true;
  xdg.configHome = "${config.home.homeDirectory}/custom-config";
  services.colima = {
    enable = true;
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
      assertion = config.home.activation ? colima-writableMutableSettings;
      message = "Colima mutable activation must follow enable.";
    }
    {
      assertion = activation.after == [ "linkGeneration" ];
      message = "Colima mutable settings must merge after linking.";
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
      assertion = cfg.colimaHomeDir == "custom-config/colima";
      message = "Colima home must honor state version, XDG, and custom paths.";
    }
    {
      assertion = (
        if pkgs.stdenv.hostPlatform.isLinux then
          lib.any (lib.hasInfix "--save-config=false") config.systemd.user.services.colima-writable.Service.ExecStart
          && config.systemd.user.services.colima-writable.Service.Restart == "always"
          && config.systemd.user.services.colima-writable.Service.RestartSec == 2
        else
          lib.elem "--save-config=false" config.launchd.agents.colima-writable.config.ProgramArguments
      );
      message = "Colima services must disable config saving and retain restart behavior.";
    }
  ];
  nmt.script = ''
    assertFileContent "home-files/custom-config/colima/immutable/colima.yaml" ${./immutable-settings.yaml}
    generated="$(grep -o '/nix/store/[^ ]*-colima.yaml' "$TESTED/activate")" \
      || fail "Missing colima.yaml input in activation"
    assertFileContent "$generated" ${./mutable-input.yaml}
    assertFileContains activate '${config.home.homeDirectory}/custom-config/colima/writable/colima.yaml'
    assertPathNotExists "home-files/custom-config/colima/writable/colima.yaml"
    assertPathNotExists "home-files/custom-config/colima/empty/colima.yaml"
  '';
}
