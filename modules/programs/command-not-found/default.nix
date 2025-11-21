# Adapted from Nixpkgs.

{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.command-not-found;
  cnfScript = pkgs.replaceVars ./command-not-found.pl {
    inherit (cfg) dbPath;
    perl = pkgs.perl.withPackages (p: [
      p.DBDSQLite
      p.StringShellQuote
    ]);
  };
  commandNotFound = pkgs.runCommand "command-not-found" { } ''
    install -Dm555 ${cnfScript} $out/bin/command-not-found
  '';
in
{
  options.programs.command-not-found = {
    enable = lib.mkEnableOption "command-not-found hook for interactive shell";

    dbPath = lib.mkOption {
      default = "/nix/var/nix/profiles/per-user/root/channels/nixos/programs.sqlite";
      description = ''
        Absolute path to {file}`programs.sqlite`. By
        default this file will be provided by your channel
        (nixexprs.tar.xz).
      '';
      type = lib.types.path;
    };
  };

  config = lib.mkIf cfg.enable {
    programs.bash.initExtra = ''
      command_not_found_handle() {
        '${commandNotFound}/bin/command-not-found' "$@"
      }
    '';

    programs.zsh.initContent = ''
      command_not_found_handler() {
        '${commandNotFound}/bin/command-not-found' "$@"
      }
    '';

    # NOTE: Fish by itself checks for nixos command-not-found, let's instead makes it explicit.
    programs.fish.interactiveShellInit = ''
      function fish_command_not_found
        "${commandNotFound}/bin/command-not-found" $argv
      end
    '';

    home.packages = [ commandNotFound ];
  };
}
