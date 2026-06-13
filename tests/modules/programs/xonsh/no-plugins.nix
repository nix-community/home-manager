{ ... }:
{
  config = {
    programs.xonsh = {
      enable = true;

      plugins = [ ];
    };

    nmt = {
      description = "if xonsh.plugins is empty, the rc.d directory should not exist";
      script = ''
        assertPathNotExists home-files/.config/xonsh/rc.d
      '';
    };
  };
}
