{ config, pkgs, ... }: {
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

    nixpkgs.overlays =
      [ (self: super: { sxhkd = pkgs.writeScriptBin "dummy-sxhkd" ""; }) ];

    nmt.script = ''
      sxhkdrc=$home_files/.config/sxhkd/sxhkdrc

      assertFileExists $sxhkdrc

      assertFileContent $sxhkdrc ${./sxhkdrc}
    '';
  };
}
