{ lib, pkgs, ... }:
let
  myProg = pkgs.writeText "my-prog.fish" ''
    complete -c myprog -s o -l output
  '';

  myApp = pkgs.writeText "my-app.fish" ''
    complete -c myapp -s -v
  '';
in
{
  config = {
    programs.fish = {
      enable = true;

      completions = {
        my-prog = ''
          complete -c myprog -s o -l output
        '';
        my-app = {
          body = ''
            complete -c myapp -s -v
          '';
        };
      };
    };

    xdg.dataFile."fish/home-manager/generated_completions".source = lib.mkForce (
      builtins.toFile "empty" ""
    );

    nmt = {
      description = "if fish.completions is set, check file exists and contents match";
      script = ''
        assertFileExists home-files/.config/fish/completions/my-prog.fish
        echo ${myProg}
        assertFileContent home-files/.config/fish/completions/my-prog.fish ${myProg}

        assertFileExists home-files/.config/fish/completions/my-app.fish
        echo ${myApp}
        assertFileContent home-files/.config/fish/completions/my-app.fish ${myApp}
      '';
    };
  };
}
