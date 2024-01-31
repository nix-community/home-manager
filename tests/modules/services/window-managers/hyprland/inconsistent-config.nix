{ config, lib, ... }:

{
  wayland.windowManager.hyprland = {
    enable = true;
    package = lib.makeOverridable
      (attrs: config.lib.test.mkStubPackage { name = "hyprland"; }) { };
    plugins =
      [ "/path/to/plugin1" (config.lib.test.mkStubPackage { name = "foo"; }) ];
  };

  test.asserts.warnings.expected = [
    "You have enabled hyprland.systemd.enable or listed plugins in hyprland.plugins but do not have any configuration in hyprland.settings or hyprland.extraConfig. This is almost certainly a mistake."
  ];
  test.asserts.warnings.enable = true;

  nmt.script = ''
    config=home-files/.config/hypr/hyprland.conf
    assertFileExists "$config"
  '';
}
