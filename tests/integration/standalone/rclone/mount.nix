{ pkgs, lib, ... }:
let
  sshKeys = import "${pkgs.path}/nixos/tests/ssh-keys.nix" pkgs;
in
{
  programs.rclone.remotes = {
    alices-sftp-remote = {
      config = {
        type = "sftp";
        host = "remote";
        user = "alice";
        # https://rclone.org/sftp/#ssh-authentication
        key_pem = lib.pipe sshKeys.snakeOilEd25519PrivateKey.text [
          lib.trim
          (lib.replaceStrings [ "\n" ] [ "\\n" ])
        ];
        known_hosts = sshKeys.snakeOilEd25519PublicKey;
      };
      mounts = {
        "/home/alice/files" = {
          enable = true;
          mountPoint = "/home/alice/remote-files";
        };
      };
    };
  };
}
