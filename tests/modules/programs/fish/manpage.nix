{ lib, pkgs, ... }: {
  config = {
    programs.fish = { enable = true; };

    home.packages = [
      (pkgs.runCommand "manpage-with-space" { } ''
        mkdir -p $out/share/man/man1
        echo "It works!" >"$out/share/man/man1/hello -inject.1"
      '')
    ];
  };
}
