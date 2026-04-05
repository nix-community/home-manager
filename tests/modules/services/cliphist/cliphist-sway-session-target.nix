{ lib, options, ... }:

{
  services.cliphist = {
    enable = true;
    systemdTarget = "sway-session.target";
  };

  nmt.script = ''
    assertFileExists home-files/.config/systemd/user/cliphist.service
    assertFileExists home-files/.config/systemd/user/sway-session.target.wants/cliphist.service
  '';

  test.asserts.warnings.expected = [
    "The option `services.cliphist.systemdTarget' defined in ${lib.showFiles options.services.cliphist.systemdTarget.files} has been changed to `services.cliphist.systemdTargets' that has a different type. Please read `services.cliphist.systemdTargets' documentation and update your configuration accordingly."
  ];

}
