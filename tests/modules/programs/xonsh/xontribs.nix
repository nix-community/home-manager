{ ... }:
{
  config = {
    programs.xonsh = {
      enable = true;

      xontribs = [
        "vox"
        "coreutils"
        "mpl"
      ];
    };

    nmt = {
      description = "if xonsh.xontribs is set, rc.xsh should contain a xontrib load line with all names";
      script = ''
        assertFileContains home-files/.config/xonsh/rc.xsh \
          "xontrib load vox coreutils mpl"
      '';
    };
  };
}
