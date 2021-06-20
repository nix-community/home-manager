# Adapted from Nixpkgs.

{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.command-not-found;
  commandNotFound = pkgs.substituteAll {
    name = "command-not-found";
    dir = "bin";
    src = ./command-not-found.pl;
    isExecutable = true;
    inherit (cfg) dbPath;
    perl = pkgs.perl.withPackages (p: [ p.DBDSQLite p.StringShellQuote ]);
  };

  shInit = commandNotFoundHandlerName: ''
    # This function is called whenever a command is not found.
    ${commandNotFoundHandlerName}() {
      local p=${commandNotFound}/bin/command-not-found
      if [ -x $p -a -f ${cfg.dbPath} ]; then
        # Run the helper program.
        $p "$@"
      else
        echo "$1: command not found" >&2
        return 127
      fi
    }
  '';

in {
  options.programs.command-not-found = {
    enable = mkEnableOption "command-not-found hook for interactive shell";

    dbPath = mkOption {
      default =
        "/nix/var/nix/profiles/per-user/root/channels/nixos/programs.sqlite";
      description = ''
        Absolute path to <filename>programs.sqlite</filename>. By
        default this file will be provided by your channel
        (nixexprs.tar.xz).
      '';
      type = types.path;
    };
  };

  config = mkIf cfg.enable {
    programs.bash.initExtra = shInit "command_not_found_handle";
    programs.zsh.initExtra = shInit "command_not_found_handler";

    home.packages = [ commandNotFound ];
  };
}
