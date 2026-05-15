{ lib, pkgs, ... }:

lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  ssh-tpm-agent-as-ssh-agent-proxy = ./as-ssh-agent-proxy.nix;
  ssh-tpm-agent-extra-args = ./extra-args.nix;
  ssh-tpm-agent-ssh-askpass = ./ssh-askpass.nix;
  ssh-tpm-agent-sshAuthSock = ./ssh-auth-sock.nix;
  ssh-tpm-agent-standalone = ./standalone.nix;
}
