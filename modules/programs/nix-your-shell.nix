{ config, lib, pkgs, ... }:
let
  inherit (lib) genAttrs getExe;
  cfg = config.programs.nix-your-shell;

  # In principle `bash` is supported too, but...  😹
  shells = [ "fish" "ion" "nushell" "zsh" ];
  programs = [ "nix" "nix-shell" ];
in {
  meta.maintainers = with lib.maintainers; [ nicoo ];

  options.programs.nix-your-shell.enable = lib.mkEnableOption ''
    `nix-your-shell`, a wrapper for `nix develop` or `nix-shell`
    to run the same shell inside the new environment.
  '';

  config.programs = lib.mkIf cfg.enable (genAttrs shells (shell: {
    shellAliases = genAttrs programs
      (program: "${getExe pkgs.nix-your-shell} ${shell} ${program} --");
  }));
}
