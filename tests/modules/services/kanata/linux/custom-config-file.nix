{ pkgs, ... }:
{
  test.stubs.kanata = { };

  services.kanata = {
    enable = true;
    keyboards.custom = {
      configFile = pkgs.writeText "my-kanata.kbd" ''
        (defcfg linux-dev "/dev/input/by-id/usb-Example_KB-event-kbd")
        (defsrc caps)
        (deflayer base esc)
      '';
    };
  };

  nmt.script = ''
    serviceFile=home-files/.config/systemd/user/kanata-custom.service
    assertFileExists "$serviceFile"
    assertFileRegex "$serviceFile" 'ExecStart=.*--cfg.*my-kanata\.kbd'
  '';
}
