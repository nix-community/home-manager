{ lib, pkgs, ... }:

lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  ssh-tpm-agent-as-ssh-agent-proxy = ./as-ssh-agent-proxy.nix;
  ssh-tpm-agent-ssh_auth_sock = ./ssh_auth_sock.nix;
  ssh-tpm-agent-standalone = ./standalone.nix;
}
