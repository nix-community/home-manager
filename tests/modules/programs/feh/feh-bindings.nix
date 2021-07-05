{ pkgs, ... }:

{
  config = {
    programs.feh.enable = true;

    programs.feh.buttons = {
      zoom_in = null;
      zoom_out = 4;
      next_img = "C-4";
      prev_img = [ 3 "C-3" ];
    };

    programs.feh.keybindings = {
      zoom_in = null;
      zoom_out = "minus";
      prev_img = [ "h" "Left" ];
    };

    nixpkgs.overlays =
      [ (self: super: { feh = pkgs.writeScriptBin "dummy-feh" ""; }) ];

    nmt.script = ''
      assertFileContent \
        home-files/.config/feh/buttons \
        ${./feh-bindings-expected-buttons}

      assertFileContent \
        home-files/.config/feh/keys \
        ${./feh-bindings-expected-keys}
    '';
  };
}
