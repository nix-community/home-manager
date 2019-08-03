{ config, lib, ... }:

with lib;

{
  config = {
    nix-channels = {
      nixos = "https://nixos.org/channels/nixos-19.03";
      unstable = "https://nixos.org/channels/nixos-unstable";
    };

    nmt.script = ''
      assertFileExists home-files/.nix-channels
      assertFileContent \
        home-files/.nix-channels \
        ${./nix-channels-expected.txt}
    '';
  };
}
