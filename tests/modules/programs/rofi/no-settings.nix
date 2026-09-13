{ config, ... }:
{
  programs.rofi.enable = true;

  nmt.script =
    assert builtins.elem config.programs.rofi.finalPackage config.home.packages;
    ''
      assertPathNotExists home-files/.config/rofi/config.rasi
      assertPathNotExists home-files/.local/share/rofi/themes
    '';
}
