{ config, lib, pkgs, ... }:
let
  cfg = config.programs.nix-your-shell;

  exe = lib.getExe pkgs.nix-your-shell;
  mkShellAliases = shell: {
    nix = "${exe} ${shell} nix --";
    nix-shell = "${exe} ${shell} nix-shell --";
  };
in {
  meta.maintainers = with lib.maintainers; [ nicoo ];

  options.programs.nix-your-shell.enable = lib.mkEnableOption ''
    `nix-your-shell`, a wrapper for `nix develop` or `nix-shell`
    to run the same shell inside the new environment.
  '';

  config.programs = lib.mkIf cfg.enable {
    fish.shellAliases = mkShellAliases "fish";
    ion.shellAliases = mkShellAliases "ion";
    nushell.shellAliases = mkShellAliases "nushell";
    zsh.shellAliases = mkShellAliases "zsh";
  };
}
