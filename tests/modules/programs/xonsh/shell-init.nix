{ ... }:
{
  config = {
    programs.xonsh = {
      enable = true;

      shellInit = ''
        $XONSH_SHOW_TRACEBACK = True
      '';

      loginShellInit = ''
        $XONSH_STORE_STDOUT = True
      '';

      interactiveShellInit = ''
        $COMPLETIONS_CONFIRM = True
      '';

      shellInitLast = ''
        $XONSH_AUTOPAIR = True
      '';
    };

    nmt = {
      description = "xonsh shell init phases should appear in rc.xsh in the correct blocks";
      script = ''
        assertFileContains home-files/.config/xonsh/rc.xsh \
          '$XONSH_SHOW_TRACEBACK = True'
        assertFileContains home-files/.config/xonsh/rc.xsh \
          '$XONSH_LOGIN'
        assertFileContains home-files/.config/xonsh/rc.xsh \
          '$XONSH_STORE_STDOUT = True'
        assertFileContains home-files/.config/xonsh/rc.xsh \
          '$XONSH_INTERACTIVE'
        assertFileContains home-files/.config/xonsh/rc.xsh \
          '$COMPLETIONS_CONFIRM = True'
        assertFileContains home-files/.config/xonsh/rc.xsh \
          '$XONSH_AUTOPAIR = True'
      '';
    };
  };
}
