{ pkgs, ... }:

{
  programs.qutebrowser = {
    enable = true;

    quickmarks = {
      nixpkgs = "https://github.com/NixOS/nixpkgs";
      home-manager = "https://github.com/nix-community/home-manager";
    };
  };

  nmt.script = let
    quickmarksFile = if pkgs.stdenv.hostPlatform.isDarwin then
      ".qutebrowser/quickmarks"
    else
      ".config/qutebrowser/quickmarks";
  in ''
    assertFileContent \
      home-files/${quickmarksFile} \
      ${
        builtins.toFile "qutebrowser-expected-quickmarks" ''
          home-manager https://github.com/nix-community/home-manager
          nixpkgs https://github.com/NixOS/nixpkgs''
      }
  '';
}
