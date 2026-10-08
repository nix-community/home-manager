{ lib, options, ... }:

{
  config = {
    test.asserts.warnings.expected = [
      "The option `programs.man.extraConfig' defined in ${lib.showFiles options.programs.man.extraConfig.files} has been renamed to `programs.man.man-db.extraConfig'."
    ];

    programs.man = {
      enable = true;
      generateCaches = true;
      extraConfig = ''
        MANDATORY_MANPATH /usr/man
        SECTION 1 n l 8
      '';
    };

    nmt.script = ''
      assertFileExists home-files/.manpath
      assertFileContains home-files/.manpath 'MANDATORY_MANPATH /usr/man'
      assertFileContains home-files/.manpath 'SECTION 1 n l 8'
    '';
  };
}
