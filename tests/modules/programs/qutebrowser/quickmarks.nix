{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    programs.qutebrowser = {
      enable = true;

      quickmarks = {
        nixpkgs = "https://github.com/NixOS/nixpkgs";
        home-manager = "https://github.com/nix-community/home-manager";
      };
    };

    test.stubs.qutebrowser = { };

    nmt.script = let
      quickmarksFile = if pkgs.stdenv.hostPlatform.isDarwin then
        ".qutebrowser/quickmarks"
      else
        ".config/qutebrowser/quickmarks";
    in ''
      assertFileContent \
        home-files/${quickmarksFile} \
        ${
          pkgs.writeText "qutebrowser-expected-quickmarks" ''
            home-manager https://github.com/nix-community/home-manager
            nixpkgs https://github.com/NixOS/nixpkgs''
        }
    '';
  };
}
