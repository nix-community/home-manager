{ ... }:
{
  config = {
    programs.xonsh.enable = true;

    nmt = {
      description = "if xonsh is enabled, rc.xsh should exist and contain the header";
      script = ''
        assertFileExists home-files/.config/xonsh/rc.xsh
        assertFileContains home-files/.config/xonsh/rc.xsh \
          "DO NOT EDIT"
      '';
    };
  };
}
