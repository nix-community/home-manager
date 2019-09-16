{ config, ... }:
{
  config = {
    services.sxhkd = {
      enable = true;

      keybindings = {
        "super + a" = "run command a";
        "super + b" = null;
        "super + Shift + b" = "run command b";
      };

      extraConfig = ''
        super + c
          call command c
 
        # comment
        super + d
          call command d
      '';
    };

    nmt.script = ''
      local sxhkdrc=home-files/.config/sxhkd/sxhkdrc

      assertFileExists $sxhkdrc

      assertFileContent $sxhkdrc ${./sxhkdrc}
    '';
  };
}
