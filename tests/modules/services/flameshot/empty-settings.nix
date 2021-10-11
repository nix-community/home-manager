{ ... }:

{
  config = {
    services.flameshot = { enable = true; };

    test.stubs.flameshot = { };

    nmt.script = ''
      assertPathNotExists home-files/.config/flameshot/flameshot.ini
    '';
  };
}
