{ config, pkgs, ... }:

{
  config = {
    nixpkgs.overlays = [ (import ./fcitx5-overlay.nix) ];
    i18n.inputMethod = {
      enabled = "fcitx5";
      fcitx5.addons = with pkgs; [ fcitx5-chinese-addons ];
    };

    nmt.script = ''
      assertFileExists home-files/.config/systemd/user/fcitx5-daemon.service
    '';
  };
}
