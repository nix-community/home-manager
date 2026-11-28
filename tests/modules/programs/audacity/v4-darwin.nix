{
  config,
  lib,
  ...
}:

{
  programs.audacity = {
    enable = true;
    package = config.lib.test.mkStubPackage { version = "4.0.0"; };
    settings.sections.application.checkForUpdate = false;
  };

  home.homeDirectory = lib.mkForce "/@TMPDIR@/hm-user";

  test.asserts.warnings.expected = [
    "programs.audacity.settings has no effect for Audacity 4 on macOS."
  ];
  test.asserts.warnings.enable = true;

  assertions = [
    {
      assertion = !(config.home.activation ? audacitySettings);
      message = "Audacity 4 settings should not create an activation action on macOS.";
    }
  ];

  nmt.script = ''
    [[ ! -e home-files/.config/Audacity/Audacity4.ini ]]
    [[ ! -e "home-files/Library/Application Support/audacity/audacity.cfg" ]]
  '';
}
