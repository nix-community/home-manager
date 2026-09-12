{ ... }:
{
  config = {
    programs.xonsh = {
      enable = true;

      shellAliases = {
        g = "git";
        ll = "ls -l";
        ".." = "cd ..";
      };
    };

    nmt = {
      description = "if xonsh.shellAliases is set, rc.xsh should contain aliases dict assignments";
      script = ''
        assertFileContains home-files/.config/xonsh/rc.xsh \
          'aliases["g"] = "git"'
        assertFileContains home-files/.config/xonsh/rc.xsh \
          'aliases["ll"] = "ls -l"'
        assertFileContains home-files/.config/xonsh/rc.xsh \
          'aliases[".."] = "cd .."'
      '';
    };
  };
}
