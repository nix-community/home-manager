{ pkgs, ... }:

{
  config = {
    programs.ncmpcpp.enable = true;
    programs.ncmpcpp.mpdMusicDir = "/home/user/music";

    nixpkgs.overlays =
      [ (self: super: { ncmpcpp = pkgs.writeScriptBin "dummy-ncmpcpp" ""; }) ];

    nmt.script = ''
      assertFileContent \
        home-files/.config/ncmpcpp/config \
        ${./ncmpcpp-empty-settings-expected-config}

      assertPathNotExists home-files/.config/ncmpcpp/bindings
    '';
  };
}
