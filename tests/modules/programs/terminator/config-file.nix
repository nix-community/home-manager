{ config, lib, pkgs, ... }: {
  config = {
    programs.terminator = {
      enable = true;
      config = {
        global_config.borderless = true;
        profiles.default.background_color = "#002b36";
      };
    };

    nixpkgs.overlays =
      [ (self: super: { terminator = pkgs.writeScriptBin "dummy" ""; }) ];

    nmt.script = ''
      assertFileContent home-files/.config/terminator/config ${
        pkgs.writeText "expected" ''
          [global_config]
          borderless = True
          [profiles]
          [[default]]
          background_color = "#002b36"''
      }
    '';
  };
}
