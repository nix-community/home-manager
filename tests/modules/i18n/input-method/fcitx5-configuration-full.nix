{ pkgs, ... }:

{
  imports = [ ./fcitx5-stubs.nix ];

  i18n.inputMethod = {
    enabled = "fcitx5";
    fcitx5 = {
      addons = with pkgs; [ fcitx5-mozc ];

      inputs = [{
        name = "Default";
        defaultLayout = "us";
        defaultIm = "mozc";
        items = [ { name = "keyboard-us"; } { name = "mozc"; } ];
      }];
    };
  };

  nmt.script = ''
    assertFileContent \
      home-files/.config/fcitx5/profile \
      ${./fcitx5-profile}
  '';
}
