{ lib, config, pkgs, ... }:

let
  exampleChannel = pkgs.writeTextDir "default.nix" ''
    { pkgs ? import <nixpkgs> { } }:

    {
      example = pkgs.emptyDirectory;
    }
  '';
in {
  config = {
    nix = {
      package = config.lib.test.mkStubPackage {
        version = lib.getVersion pkgs.nixVersions.stable;
      };
      channels.example = exampleChannel;
      settings.use-xdg-base-directories = true;
    };

    nmt.script = ''
      assertFileContains home-path/etc/profile.d/hm-session-vars.sh \
        'export NIX_PATH="/home/hm-user/.local/state/nix/defexpr/50-home-manager''${NIX_PATH:+:$NIX_PATH}"'
      assertFileContent \
        home-files/.local/state/nix/defexpr/50-home-manager/example/default.nix \
        ${exampleChannel}/default.nix
    '';
  };
}
