{ config, lib, pkgs, ... }:

with lib;

let

  mergeSets = sets: lists.fold attrsets.recursiveUpdate { } sets;

  yaml = pkgs.formats.yaml { };

  cfg = config.services.udiskie;

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
      enable = mkEnableOption "udiskie mount daemon" // {
        description = ''
          Whether to enable the udiskie mount daemon.
          </para><para>
          Note, if you use NixOS then you must add
          <code>services.udisks2.enable = true</code>
          to your system configuration. Otherwise mounting will fail because
          the Udisk2 DBus service is not found.
        '';
      };

      settings = mkOption {
        type = yaml.type;
        default = { };
        example = literalExpression ''
          {
            program_options = {
              udisks_version = 2;
              tray = true;
            };
            icon_names.media = [ "media-optical" ];
          }
        '';
        description = ''
          Configuration written to
          <filename>$XDG_CONFIG_HOME/udiskie/config.yml</filename>.
          </para><para>
          See <link xlink:href="https://github.com/coldfix/udiskie/blob/master/doc/udiskie.8.txt#configuration" />
          for the full list of options.
        '';
      };

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
    assertions = [
      (hm.assertions.assertPlatform "services.udiskie" pkgs platforms.linux)
    ];

    xdg.configFile."udiskie/config.yml".source =
      yaml.generate "udiskie-config.yml" (mergeSets [
        {
          program_options = {
            automount = cfg.automount;
            tray = if cfg.tray == "always" then
              true
            else if cfg.tray == "never" then
              false
            else
              "auto";
            notify = cfg.notify;
          };
        }
        cfg.settings
      ]);

    systemd.user.services.udiskie = {
      Unit = {
        Description = "udiskie mount daemon";
        Requires = lib.optional (cfg.tray != "never") "tray.target";
        After = [ "graphical-session-pre.target" ]
          ++ lib.optional (cfg.tray != "never") "tray.target";
        PartOf = [ "graphical-session.target" ];
      };

      Service.ExecStart = toString ([ "${pkgs.udiskie}/bin/udiskie" ]
        ++ optional config.xsession.preferStatusNotifierItems "--appindicator");

      Install.WantedBy = [ "graphical-session.target" ];
    };
  };
}
