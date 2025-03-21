{ config, pkgs, ... }: {
  services.davmail = {
    enable = true;
    imitateOutlook = true;
  };

  nmt.script = ''
    serviceFile=home-files/.config/systemd/user/davmail.service
    assertFileExists $serviceFile
    configFile=$(grep -o '/nix/store/.*-davmail.properties' $TESTED/$serviceFile)
    assertFileExists $configFile
    assertFileContent $configFile ${
      pkgs.writeText "imitateOutlook.properties" ''
        # Generated with Nix

        davmail.caldavPort = 1080
        davmail.disableUpdateCheck = true
        davmail.imapPort = 1143
        davmail.ldapPort = 1389
        davmail.logFilePath = ${config.xdg.stateHome}/davmail.log
        davmail.logFileSize = 1MB
        davmail.mode = auto
        davmail.oauth.clientId = d3590ed6-52b3-4102-aeff-aad2292ab01c
        davmail.oauth.redirectUri = urn:ietf:wg:oauth:2.0:oob
        davmail.oauth.tokenFilePath = ${config.xdg.stateHome}/davmail-tokens
        davmail.popPort = 1110
        davmail.server = true
        davmail.smtpPort = 1025
        davmail.url = https://outlook.office365.com/EWS/Exchange.asmx
        log4j.logger.davmail = WARN
        log4j.logger.httpclient.wire = WARN
        log4j.logger.org.apache.commons.httpclient = WARN
        log4j.rootLogger = WARN
      ''
    }
  '';
}
