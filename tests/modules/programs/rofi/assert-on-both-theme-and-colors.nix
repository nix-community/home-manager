{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    programs.rofi = {
      enable = true;
      theme = "foo";
      colors = {
        window = {
          background = "background";
          border = "border";
          separator = "separator";
        };
        rows = { };
      };
    };

    home.file.result.text = builtins.toJSON
      (map (a: a.message) (filter (a: !a.assertion) config.assertions));

    nixpkgs.overlays =
      [ (self: super: { rofi = pkgs.writeScriptBin "dummy-rofi" ""; }) ];

    nmt.script = ''
      assertFileContent \
        $home_files/result \
        ${./assert-on-both-theme-and-colors-expected.json}
    '';
  };
}
