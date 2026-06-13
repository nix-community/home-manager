{ pkgs, ... }:

{
  config = {
    programs.wrtag = {
      enable = true;
      package = pkgs.writeScriptBin "dummy-wrtag" "";
    };

    nmt.script = ''
      assertPathNotExists home-files/.config/wrtag/config
    '';
  };
}
