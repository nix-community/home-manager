{ config, lib, pkgs, ... }:

with lib;
let cfg = config.services.barrier;
in {

  meta.maintainers = with maintainers; [ kritnich ];

  imports = [
    (mkRemovedOptionModule [ "services" "barrier" "client" "tray" ] ''
      The tray option is non-functional and has been removed.
    '')
  ];

  options.services.barrier = {

    client = {

      enable = mkEnableOption "Barrier Client daemon";

      name = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = ''
          Screen name of client. Defaults to hostname.
        '';
      };

      server = mkOption {
        type = types.str;
        description = ''
          Server to connect to formatted as
          <literal>&lt;host&gt;[:&lt;port&gt;]</literal>.
          Port defaults to <literal>24800</literal>.
        '';
      };

      enableCrypto = mkEnableOption "crypto (SSL) plugin" // {
        default = true;
      };

      enableDragDrop = mkEnableOption "file drag &amp; drop";

      extraFlags = mkOption {
        type = types.listOf types.str;
        default = [ "-f" ];
        defaultText = literalExpression ''[ "-f" ]'';
        description = ''
          Additional flags to pass to <command>barrierc</command>.
          See <command>barrierc --help</command>.
        '';
      };

    };
  };

  config = mkIf cfg.client.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.barrier" pkgs
        lib.platforms.linux)
    ];

    systemd.user.services.barrierc = {
      Unit = {
        Description = "Barrier Client daemon";
        After = [ "graphical-session-pre.target" ];
        PartOf = [ "graphical-session.target" ];
      };
      Install.WantedBy = [ "graphical-session.target" ];
      Service.ExecStart = with cfg.client;
        toString ([ "${pkgs.barrier}/bin/barrierc" ]
          ++ optional (name != null) "--name ${name}"
          ++ optional enableCrypto "--enable-crypto"
          ++ optional enableDragDrop "--enable-drag-drop" ++ extraFlags
          ++ [ server ]);
    };
  };

}
