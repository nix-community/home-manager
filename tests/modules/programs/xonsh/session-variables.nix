{ ... }:
{
  config = {
    programs.xonsh = {
      enable = true;

      sessionVariables = {
        EDITOR = "nvim";
        PAGER = "less";
      };
    };

    nmt = {
      description = "if xonsh.sessionVariables is set, rc.xsh should contain xonsh env var assignments";
      script = ''
        assertFileContains home-files/.config/xonsh/rc.xsh \
          '$EDITOR = "nvim"'
        assertFileContains home-files/.config/xonsh/rc.xsh \
          '$PAGER = "less"'
      '';
    };
  };
}
