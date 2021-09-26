{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    programs = {
      bash.enable = true;

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

    test.stubs.powerline-go = { };

    nmt.script = ''
      assertFileExists home-files/.bashrc
      assertFileContains \
        home-files/.bashrc \
        '/bin/powerline-go -error $old_exit_status -modules nix-shell -newline -path-aliases \~/project/foo=prj-foo -ignore-repos /home/me/project1,/home/me/project2'
    '';
  };
}
