{ ... }:
{
  config = {
    programs.xonsh = {
      enable = true;

      xonshrcExtra = ''
        $XONSH_HISTORY_MATCH_ANYWHERE = True
      '';
    };

    nmt = {
      description = "if xonsh.xonshrcExtra is set, rc.xsh should contain the extra config verbatim";
      script = ''
        assertFileContains home-files/.config/xonsh/rc.xsh \
          '$XONSH_HISTORY_MATCH_ANYWHERE = True'
      '';
    };
  };
}
