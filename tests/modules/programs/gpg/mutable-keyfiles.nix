{ config, lib, pkgs, ... }:

{
  programs.gpg = {
    enable = true;

    publicKeys = [
      {
        source = builtins.toFile "key1" "key1";
        trust = 1;
      }
      { source = builtins.toFile "key2" "key2"; }
    ];
  };

  test.stubs.gnupg = { };
  test.stubs.systemd = { }; # depends on gnupg.override

  nmt.script = ''
    assertFileContains activate "export GNUPGHOME=/home/hm-user/.gnupg"

    assertFileContains activate "unset GNUPGHOME QUIET_ARG keyId importTrust"

    assertFileRegex activate \
      '^run @gnupg@/bin/gpg \$QUIET_ARG --import /nix/store/[0-9a-z]*-key1$'
    assertFileRegex activate \
      '^run importTrust "/nix/store/[0-9a-z]*-key1" 1$'
    assertFileRegex activate \
      '^run @gnupg@/bin/gpg \$QUIET_ARG --import /nix/store/[0-9a-z]*-key2$'
  '';
}
