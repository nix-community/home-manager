{ config, lib, pkgs, options, ... }: {
  config = {
    programs.kitty = {
      enable = true;
      theme = "Space Gray Eighties";
    };

    test.stubs.kitty = { };

    test.asserts.warnings.enable = true;
    test.asserts.warnings.expected = [
      ("The option `programs.kitty.theme' defined in ${
          lib.showFiles options.programs.kitty.theme.files
        } has been changed to `programs.kitty.themeFile' that has a different"
        + " type. Please read `programs.kitty.themeFile' documentation and"
        + " update your configuration accordingly.")
    ];

    nmt.script = ''
      assertFileExists home-files/.config/kitty/kitty.conf
      assertFileRegex home-files/.config/kitty/kitty.conf "^include .*themes/SpaceGray_Eighties\.conf$"
    '';
  };
}
