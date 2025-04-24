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
    programs.bash.initExtra = shInit "command_not_found_handle";
    programs.zsh.initContent = shInit "command_not_found_handler";

    home.packages = [ commandNotFound ];
  };
}
