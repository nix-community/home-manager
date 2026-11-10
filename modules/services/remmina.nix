{
  config,
  lib,
  pkgs,
  ...
}:

let

  inherit (lib)
    mkIf
    mkMerge
    mkEnableOption
    mkPackageOption
    mkOption
    ;

  cfg = config.services.remmina;

  iniFormat = pkgs.formats.ini { };

  # Remmina rewrites its preferences and profiles (window geometry, saved
  # passwords), so the declared options are merged into the files in place.
  mergeIni =
    path: settings:
    let
      file = lib.escapeShellArg path;
      static = iniFormat.generate "remmina-settings" settings;
    in
    ''
      [[ -e ${file} ]] || run install -D -m600 ${static} ${file}
      run ${lib.getExe pkgs.crudini} --merge --ini-options=nospace ${file} < ${static}
    '';

in
{
  meta.maintainers = with lib.maintainers; [ cyntheticfox ];

  options.services.remmina = {
    enable = mkEnableOption "Remmina";

    package = mkPackageOption pkgs "remmina" { };

    addRdpMimeTypeAssoc = mkEnableOption "Remmina RDP file open option" // {
      default = true;
    };

    settings = mkOption {
      inherit (iniFormat) type;
      default = { };
      example = {
        remmina_pref = {
          dark_theme = true;
          rdp_quality_9 = "A7";
        };
      };
      description = ''
        Preferences merged into
        {file}`$XDG_CONFIG_HOME/remmina/remmina.pref` on activation.

        Remmina rewrites this file itself, so it is not linked from the
        Nix store. Options that Remmina or the user added are kept, and
        options removed from this set are not removed from the file.
        Remmina saves its in-memory preferences when it exits, so activate
        while it is not running.
      '';
    };

    profiles = mkOption {
      type = with lib.types; attrsOf (attrsOf iniFormat.lib.types.atom);
      default = { };
      example = {
        workstation = {
          name = "Workstation";
          protocol = "RDP";
          server = "workstation.example.org";
          username = "alice";
          quality = 9;
        };
      };
      description = ''
        Connection profiles. Each one is merged into
        {file}`$XDG_DATA_HOME/remmina/<name>.remmina` on activation, with
        the same semantics as {option}`services.remmina.settings`.

        Do not set passwords here, they would end up in the world-readable
        Nix store. Remmina saves them to the keyring or to the profile
        itself, and the merge preserves them.
      '';
    };

    systemdService = {
      enable = mkEnableOption "systemd Remmina service" // {
        default = true;
      };

      startupFlags = mkOption {
        type = with lib.types; listOf str;
        default = [ "--icon" ];
        description = ''
          Startup flags documented in the manpage to run at service startup.
        '';
      };
    };
  };

  config = mkIf cfg.enable (mkMerge [
    { home.packages = [ cfg.package ]; }

    (mkIf cfg.systemdService.enable {
      systemd.user.services.remmina = {
        Unit = {
          Description = "Remmina remote desktop client";
          Documentation = "man:remmina(1)";
          Requires = [ "graphical-session.target" ];
        };

        Service = {
          Type = "simple";
          ExecStart = "${lib.getExe cfg.package} ${lib.escapeShellArgs cfg.systemdService.startupFlags}";
          Restart = "on-failure";
        };

        Install.WantedBy = [ "graphical-session.target" ];
      };
    })

    (mkIf (cfg.settings != { } || cfg.profiles != { }) {
      # Merge before the systemd service can start Remmina, which would
      # otherwise save its stale in-memory preferences over the merge.
      home.activation.remminaSettings = lib.hm.dag.entryBetween [ "reloadSystemd" ] [ "writeBoundary" ] (
        lib.optionalString (cfg.settings != { }) (
          mergeIni "${config.xdg.configHome}/remmina/remmina.pref" cfg.settings
        )
        + lib.concatStrings (
          lib.mapAttrsToList (
            name: profile: mergeIni "${config.xdg.dataHome}/remmina/${name}.remmina" { remmina = profile; }
          ) cfg.profiles
        )
      );
    })

    (mkIf (config.xdg.mimeApps.enable && cfg.addRdpMimeTypeAssoc) {
      xdg.mimeApps.associations.added."application/x-rdp" = "org.remmina.Remmina.desktop";

      xdg.dataFile."mime/packages/application-x-rdp.xml".text = ''
        <?xml version="1.0" encoding="UTF-8"?>
        <mime-info xmlns="http://www.freedesktop.org/standards/shared-mime-info">
          <mime-type type="application/x-rdp">
            <comment>rdp file</comment>
            <icon name="application-x-rdp"/>
            <glob-deleteall/>
            <glob pattern="*.rdp"/>
          </mime-type>
        </mime-info>
      '';
    })
  ]);
}
