{ pkgs, ... }:

{
  config = {
    programs.feh.enable = true;

    test.stubs.feh = { };

    nmt.script = ''
      assertPathNotExists home-files/.config/feh/buttons
      assertPathNotExists home-files/.config/feh/keys
    '';
  };
}
