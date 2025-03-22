{ config, lib, pkgs, ... }:
let

  inherit (lib)
    attrNames boolToString concatMap concatStringsSep isAttrs isBool
    mapAttrsRecursive mkDefault mkEnableOption mkIf mkOption optionalAttrs
    types;

  cfg = config.services.davmail;

  settingsType = with types;
    oneOf [ (attrsOf settingsType) str int bool ] // {
      description =
        "DavMail settings type (str, int, bool or attribute set thereof)";
    };

  toStr = val: if isBool val then boolToString val else toString val;

  linesForAttrs = attrs:
    concatMap (name:
      let value = attrs.${name};
      in if isAttrs value then
        map (line: name + "." + line) (linesForAttrs value)
      else
        [ "${name}=${toStr value}" ]) (attrNames attrs);

  settingsFile = pkgs.writeText "davmail.properties"
    (concatStringsSep "\n" (linesForAttrs cfg.settings));

in {

  meta.maintainers = [ lib.maintainers.bmrips ];

  options.services.davmail = {

    enable = mkEnableOption "DavMail, an MS Exchange gateway.";

    imitateOutlook = mkOption {
      type = types.bool;
      default = false;
      description = "Whether DavMail pretends to be Outlook.";
      example = true;
    };

    settings = mkOption {
      type = settingsType;
      default = { };
      description = ''
        Davmail configuration. Refer to
        <http://davmail.sourceforge.net/serversetup.html>
        and <http://davmail.sourceforge.net/advanced.html>
        for details on supported values.
      '';
      example = {
        davmail.url = "https://outlook.office365.com/EWS/Exchange.asmx";
        davmail.allowRemote = true;
        davmail.imapPort = 55555;
        davmail.bindAddress = "10.0.1.2";
        davmail.smtpSaveInSent = true;
        davmail.folderSizeLimit = 10;
        davmail.caldavAutoSchedule = false;
        log4j.logger.rootLogger = "DEBUG";
      };
    };

  };

  config = mkIf cfg.enable {

    assertions = [{
      assertion = pkgs.stdenv.hostPlatform.isLinux;
      message = "The DavMail service is only available on Linux.";
    }];

    services.davmail.settings = mapAttrsRecursive (_: mkDefault) {
      davmail = {
        server = true;
        disableUpdateCheck = true;
        logFilePath = "${config.xdg.stateHome}/davmail.log";
        logFileSize = "1MB";
        mode = "auto";
        url = "https://outlook.office365.com/EWS/Exchange.asmx";
        caldavPort = 1080;
        imapPort = 1143;
        ldapPort = 1389;
        popPort = 1110;
        smtpPort = 1025;
      } // optionalAttrs cfg.imitateOutlook {
        oauth.clientId = "d3590ed6-52b3-4102-aeff-aad2292ab01c";
        oauth.redirectUri = "urn:ietf:wg:oauth:2.0:oob";
      };
      log4j = {
        logger.davmail = "WARN";
        logger.httpclient.wire = "WARN";
        logger.org.apache.commons.httpclient = "WARN";
        rootLogger = "WARN";
      };
    };

    systemd.user.services.davmail = {
      Unit = {
        Description = "DavMail POP/IMAP/SMTP Exchange Gateway";
        After = [ "graphical-session.target" "network.target" ];
      };
      Install.WantedBy = [ "graphical-session.target" ];
      Service = {
        Type = "simple";
        ExecStart = "${pkgs.davmail}/bin/davmail ${settingsFile}";
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

    home.packages = [ pkgs.davmail ];

  };

}
