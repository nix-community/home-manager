{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.services.udiskie;

  commandArgs = concatStringsSep " " (map (opt: "-" + opt) [
    (if cfg.automount then "a" else "A")
    (if cfg.notify then "n" else "N")
    ({
      always = "t";
      auto = "s";
      never = "T";
    }.${cfg.tray})
  ] ++ optional config.xsession.preferStatusNotifierItems "--appindicator");

in {
  meta.maintainers = [ maintainers.rycee ];

  imports = [
    (mkRemovedOptionModule [ "services" "udiskie" "sni" ] ''
      Support for Status Notifier Items is now configured globally through the

        xsession.preferStatusNotifierItems

      option. Please change to use that instead.
    '')
  ];

  options = {
    services.udiskie = {
      enable = mkEnableOption "udiskie mount daemon";

      automount = mkOption {
        type = types.bool;
        default = true;
        description = "Whether to automatically mount new devices.";
      };

      notify = mkOption {
        type = types.bool;
        default = true;
        description = "Whether to show pop-up notifications.";
      };

      tray = mkOption {
        type = types.enum [ "always" "auto" "never" ];
        default = "auto";
        description = ''
          Whether to display tray icon.
          </para><para>
          The options are
          <variablelist>
          <varlistentry>
            <term><literal>always</literal></term>
            <listitem><para>Always show tray icon.</para></listitem>
          </varlistentry>
          <varlistentry>
            <term><literal>auto</literal></term>
            <listitem><para>
              Show tray icon only when there is a device available.
            </para></listitem>
          </varlistentry>
          <varlistentry>
            <term><literal>never</literal></term>
            <listitem><para>Never show tray icon.</para></listitem>
          </varlistentry>
          </variablelist>
        '';
      };
    };
  };

  config = mkIf config.services.udiskie.enable {
    systemd.user.services.udiskie = {
      Unit = {
        Description = "udiskie mount daemon";
        Requires = [ "tray.target" ];
        After = [ "graphical-session-pre.target" "tray.target" ];
        PartOf = [ "graphical-session.target" ];
      };

      Service = { ExecStart = "${pkgs.udiskie}/bin/udiskie ${commandArgs}"; };

      Install = { WantedBy = [ "graphical-session.target" ]; };
    };
  };
}
