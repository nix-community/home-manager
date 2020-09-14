{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    programs.nushell = {
      enable = true;

      settings = mkMerge [
        {
          edit_mode = "vi";
          startup = [ "alias la [] { ls -a }" ];
          completion_mode = "circular";
          key_timeout = 10;
        }

        {
          startup = [ "alias e [msg] { echo $msg }" ];
          no_auto_pivot = true;
        }
      ];
    };

    nixpkgs.overlays =
      [ (self: super: { nushell = pkgs.writeScriptBin "dummy-nushell" ""; }) ];

    nmt.script = ''
      assertFileContent \
        home-files/.config/nu/config.toml \
        ${./settings-expected.toml}
    '';
  };
}
