{ config, lib, pkgs, ... }:
let
  cfg = config.programs.nix-your-shell;

  exe = lib.getExe pkgs.nix-your-shell;
  args = lib.concatStringsSep " " cfg.extraArgs;

  mkShellAliases = shell: {
    nix = "${exe} ${args} ${shell} nix --";
    nix-shell = "${exe} ${args} ${shell} nix-shell --";
  };
in {
  meta.maintainers = with lib.maintainers; [ nicoo ];

  options.programs.nix-your-shell = {
    enable = lib.mkEnableOption ''
      `nix-your-shell`, a wrapper for `nix develop` or `nix-shell`
      to run the same shell inside the new environment.
    '';

    extraArgs = lib.mkOption {
      default = [ ];
      description = ''
        additional command-line arguments, to be passed to `nix-your-shell`
      '';
      type = with lib.types; listOf str;
    };
  };

  config.programs = lib.mkIf cfg.enable {
    fish.shellAliases = mkShellAliases "fish";
    ion.shellAliases = mkShellAliases "ion";
    nushell.shellAliases = mkShellAliases "nushell";
    zsh.shellAliases = mkShellAliases "zsh";
  };
}
