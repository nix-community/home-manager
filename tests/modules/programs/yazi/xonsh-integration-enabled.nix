{ ... }:

let
  shellIntegration = ''
    def init():
      def ya(args):
        tmp = $(mktemp -t "yazi-cwd.XXXXX")
        $[yazi @(args) @(f"--cwd-file={tmp}")]
        cwd = fp"{tmp}".read_text()
        if cwd != "" and cwd != $PWD:
          xonsh.dirstack.cd(cwd)
        $[rm -f -- @(tmp)]

      aliases['ya'] = ya
    init()
    del init
  '';
in {
  programs.xonsh.enable = true;

  programs.yazi = {
    enable = true;
    enableXonshIntegration = true;
  };

  test.stubs.yazi = { };

  nmt.script = ''
    assertFileContains home-files/.config/xonsh/rc.d/yazi.xsh '${shellIntegration}'
  '';
}
