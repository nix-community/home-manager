{
  config,
  lib,
  ...
}:
let
  cfg = config.services.imapgoose;
in
{
  meta.maintainers = [ lib.maintainers.philocalyst ];

  imports = [
    ./linux.nix
    ./darwin.nix
  ];

  options.services.imapgoose = {
    enable = lib.mkEnableOption "imapgoose mail synchronization service";

    frequency = lib.mkOption {
      type = lib.types.str;
      default = "hourly";
      example = "hourly";
      description = ''
        How often to run imapgoose. This value is passed to the systemd
        timer configuration as the {option}`OnCalendar` option. See
        {manpage}`systemd.time(7)` for more information about the format.

        '' + lib.hm.darwin.intervalDocumentation;
    };

    preExec = lib.mkOption {
      type = lib.types.nullOr lib.types.lines;
      default = null;
      example = "mkdir -p ~/mail";
      description = "Optional command to run before each imapgoose invocation.";
    };

    postExec = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "\${pkgs.notmuch}/bin/notmuch new";
      description = "Optional command to run after each successful imapgoose invocation.";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.imapgoose.enable = true;
  };
}
