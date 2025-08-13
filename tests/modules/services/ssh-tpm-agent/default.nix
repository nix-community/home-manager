{ lib, pkgs, ... }:

lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  ssh-tpm-agent-standalone = ./standalone.nix;
  ssh-tpm-agent-as-ssh-agent-proxy = ./as-ssh-agent-proxy.nix;
}
