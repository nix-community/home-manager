{ ... }:
{
  config = {
    programs.xonsh = {
      enable = true;

      bashCompletion.enable = true;
    };

    nmt = {
      description = "if xonsh.bashCompletion.enable is true, rc.xsh should set BASH_COMPLETIONS in the interactive block";
      script = ''
        assertFileContains home-files/.config/xonsh/rc.xsh \
          '$BASH_COMPLETIONS'
        assertFileContains home-files/.config/xonsh/rc.xsh \
          '$XONSH_INTERACTIVE'
      '';
    };
  };
}
