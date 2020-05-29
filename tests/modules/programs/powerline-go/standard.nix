{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    programs = {
      bash.enable = true;

      powerline-go = {
        enable = true;
        newline = true;
        ignoreRepos = ["/home/me/project"];
        modules = ["nix-shell"];
        pathAliases = {
          "\\~/project/foo" = "prj-foo";
        };
      };
    };

    nmt.script = ''
      assertFileExists home-files/.bashrc
      assertFileContains \
        home-files/.bashrc \
        '/bin/powerline-go -error $? -ignore-repos /home/me/project -modules nix-shell -newline -path-aliases \~/project/foo=prj-foo)"'
    '';
  };
}
