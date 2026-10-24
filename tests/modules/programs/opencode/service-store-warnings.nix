{ config, ... }:

let
  passwordFile = builtins.toFile "opencode-password" "secret";
  environmentFile = builtins.toFile "opencode-environment" "FOO=bar";
in
{
  programs.opencode = {
    enable = true;
    package = config.lib.test.mkStubPackage {
      name = "opencode";
      version = "2.1.1";
    };

    service = {
      enable = true;
      inherit passwordFile environmentFile;
    };
  };

  test.asserts.warnings.expected = [
    ''
      programs.opencode.service.passwordFile points into the Nix store.
      The password is world-readable there; use a secret manager path
      instead.
    ''
    ''
      programs.opencode.service.environmentFile points into the Nix store.
      Its values are world-readable there; use a secret manager path
      instead.
    ''
  ];
}
