{ config, lib, pkgs, ... }:
let

  inherit (lib)
    mapAttrsRecursive mkDefault mkEnableOption mkIf mkOption optionalAttrs
    types;

  cfg = config.services.davmail;

  javaProperties = pkgs.formats.javaProperties { };

  settingsFile = javaProperties.generate "davmail.properties" cfg.settings;

in {

  meta.maintainers = [ lib.hm.maintainers.bmrips ];

  options.services.davmail = {

    enable = mkEnableOption "DavMail, an MS Exchange gateway.";

    package = lib.mkPackageOption pkgs "davmail" { };

    imitateOutlook = mkOption {
      type = types.bool;
      default = false;
      description = "Whether DavMail pretends to be Outlook.";
      example = true;
    };

    settings = mkOption {
      type = javaProperties.type;
      default = { };
      description = ''
        Davmail configuration. Refer to
        <http://davmail.sourceforge.net/serversetup.html>
        and <http://davmail.sourceforge.net/advanced.html>
        for details on supported values.
      '';
      example = {
        "davmail.url" = "https://outlook.office365.com/EWS/Exchange.asmx";
        "davmail.allowRemote" = true;
        "davmail.imapPort" = 55555;
        "davmail.bindAddress" = "10.0.1.2";
        "davmail.smtpSaveInSent" = true;
        "davmail.folderSizeLimit" = 10;
        "davmail.caldavAutoSchedule" = false;
        "log4j.logger.rootLogger" = "DEBUG";
      };
    };

  };

  config = mkIf cfg.enable {

    assertions = [{
      assertion = pkgs.stdenv.hostPlatform.isLinux;
      message = "The DavMail service is only available on Linux.";
    }];

    services.davmail.settings = mapAttrsRecursive (_: mkDefault) {
      "davmail.server" = true;
      "davmail.disableUpdateCheck" = true;
      "davmail.logFilePath" = "${config.xdg.stateHome}/davmail.log";
      "davmail.logFileSize" = "1MB";
      "davmail.mode" = "auto";
      "davmail.url" = "https://outlook.office365.com/EWS/Exchange.asmx";
      "davmail.caldavPort" = 1080;
      "davmail.imapPort" = 1143;
      "davmail.ldapPort" = 1389;
      "davmail.popPort" = 1110;
      "davmail.smtpPort" = 1025;

      # The token file path is set because, otherwise, if oauth.persistToken
      # is enabled, DavMail would attempt to write the token into generated
      # configuration which lays in the Nix store.
      "davmail.oauth.tokenFilePath" = "${config.xdg.stateHome}/davmail-tokens";

      "log4j.logger.davmail" = "WARN";
      "log4j.logger.httpclient.wire" = "WARN";
      "log4j.logger.org.apache.commons.httpclient" = "WARN";
      "log4j.rootLogger" = "WARN";
    } // optionalAttrs cfg.imitateOutlook {
      "davmail.oauth.clientId" = "d3590ed6-52b3-4102-aeff-aad2292ab01c";
      "davmail.oauth.redirectUri" = "urn:ietf:wg:oauth:2.0:oob";
    };

    systemd.user.services.davmail = {
      Unit = {
        Description = "DavMail POP/IMAP/SMTP Exchange Gateway";
        After = [ "graphical-session.target" "network.target" ];
      };
      Install.WantedBy = [ "graphical-session.target" ];
      Service = {
        Type = "simple";
        ExecStart = "${lib.getExe cfg.package} ${settingsFile}";
        Restart = "on-failure";

        CapabilityBoundingSet = [ "" ];
        DeviceAllow = [ "" ];
        LockPersonality = true;
        NoNewPrivileges = true;
        PrivateDevices = true;
        PrivateTmp = true;
        PrivateUsers = true;
        ProtectClock = true;
        ProtectControlGroups = true;
        ProtectSystem = "strict";
        ProtectHostname = true;
        ProtectKernelLogs = true;
        ProtectKernelModules = true;
        ProtectKernelTunables = true;
        ProtectProc = "invisible";
        RemoveIPC = true;
        RestrictAddressFamilies = [ "AF_INET" "AF_INET6" ];
        RestrictNamespaces = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        SystemCallArchitectures = "native";
        SystemCallFilter = "@system-service";
        SystemCallErrorNumber = "EPERM";
        UMask = "0077";
      };
    };

    home.packages = [ cfg.package ];
  };
}
