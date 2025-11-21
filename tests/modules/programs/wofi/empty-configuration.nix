{ pkgs, ... }:

{
  config = {
    programs.wofi = {
      enable = true;
      package = pkgs.writeScriptBin "dummy-wofi" "";
    };

    nmt.script = ''
      assertPathNotExists home-files/.config/wofi/config
      assertPathNotExists home-files/.config/wofi/style.css
    '';
  };
}
