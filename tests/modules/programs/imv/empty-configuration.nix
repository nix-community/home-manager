{ pkgs, ... }:

{
  config = {
    programs.imv = {
      enable = true;
      package = pkgs.writeScriptBin "dummy-imv" "";
    };

    nmt.script = ''
      assertPathNotExists home-files/.config/imv/config
    '';
  };
}
