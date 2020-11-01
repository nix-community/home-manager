{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    programs = {
      zsh.enable = true;

      powerline-go = {
        enable = true;
        newline = true;
        modules = [ "nix-shell" ];
        pathAliases = { "\\~/project/foo" = "prj-foo"; };
        settings = {
          ignore-repos = [ "/home/me/project1" "/home/me/project2" ];
        };
      };
    };

    nixpkgs.overlays =
      [ (self: super: { zsh = pkgs.writeScriptBin "dummy-zsh" ""; }) ];

    nmt.script = ''
      assertFileExists home-files/.zshrc
      assertFileContains \
        home-files/.zshrc \
        '/bin/powerline-go -error $? -shell zsh -modules nix-shell -newline -path-aliases \~/project/foo=prj-foo -ignore-repos /home/me/project1,/home/me/project2'
    '';
  };
}
