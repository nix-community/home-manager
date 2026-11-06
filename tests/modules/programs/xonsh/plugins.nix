{ pkgs, ... }:
let
  myPluginSrc = pkgs.writeText "my-plugin.xsh" ''
    # my custom plugin
    aliases['hello'] = 'echo hello'
  '';
in
{
  config = {
    programs.xonsh = {
      enable = true;

      plugins = [
        {
          name = "my-plugin";
          src = myPluginSrc;
        }
      ];
    };

    nmt = {
      description = "if xonsh.plugins is set, rc.d file should exist with correct content";
      script = ''
        assertFileExists home-files/.config/xonsh/rc.d/my-plugin.xsh
        assertFileContent home-files/.config/xonsh/rc.d/my-plugin.xsh ${myPluginSrc}
      '';
    };
  };
}
