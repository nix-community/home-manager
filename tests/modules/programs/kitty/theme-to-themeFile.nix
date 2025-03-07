{ lib, options, realPkgs, ... }:

{
  programs.kitty = {
    enable = true;
    theme = "Space Gray Eighties";
  };

  test.asserts.warnings.enable = true;
  test.asserts.warnings.expected = [
    ("The option `programs.kitty.theme' defined in ${
        lib.showFiles options.programs.kitty.theme.files
      } has been changed to `programs.kitty.themeFile' that has a different"
      + " type. Please read `programs.kitty.themeFile' documentation and"
      + " update your configuration accordingly.")
  ];

  nixpkgs.overlays = [ (self: super: { inherit (realPkgs) kitty-themes; }) ];

  nmt.script = ''
    assertFileExists home-files/.config/kitty/kitty.conf
    assertFileRegex home-files/.config/kitty/kitty.conf "^include .*themes/SpaceGray_Eighties\.conf$"
  '';
}
