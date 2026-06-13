{ pkgs, ... }:
{
  config = {
    programs.xonsh = {
      enable = true;

      extraPackages = _ps: [ pkgs.git ];
    };

    nmt = {
      description = "if xonsh.extraPackages is set, xonsh should still be installed and rc.xsh should exist";
      script = ''
        assertFileExists home-path/bin/xonsh
        assertFileExists home-files/.config/xonsh/rc.xsh
        assertFileContains home-files/.config/xonsh/rc.xsh \
          "DO NOT EDIT"
      '';
    };
  };
}
