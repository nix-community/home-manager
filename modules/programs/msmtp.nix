{ config, lib, pkgs, ... }:

with lib;
with builtins;

let
  cfg = config.programs.msmtp;

  dag = config.lib.dag;

  msmtpAccounts = filter (a: a.msmtp.enable)
    (attrValues config.accounts.email.accounts);

  sendMsmtpCommand = account:
    if cfg.offlineSendMethod == "native" then
      "${pkgs.msmtp}/bin/msmtpq -C \${XDG_CONFIG_HOME:-$HOME/.config}/msmtp/config --account=${account.name} -t"
    else
      "${pkgs.msmtp}/bin/msmtp \${XDG_CONFIG_HOME:-$HOME/.config}/msmtp/config --account=${account.name} -t";

  # msmtp requires the password to finish with a newline
  passwordCommandStr = account:
    optionalString (account.passwordCommand != null)
      ''passwordeval ${pkgs.bash}/bin/bash -c "echo $(${toString account.passwordCommand})"'';

  accountStr = account: with account; ''
account ${name}
host ${smtp.host}
from ${address}
auth on
user ${if flavor == "gmail" then address else userName}
tls ${if smtp.tls.enable then "on" else "off"}
${optionalString (smtp.tls.certificatesFile != null) "tls_trust_file ${smtp.tls.certificatesFile}"}
port ${builtins.toString smtp.port}
${passwordCommandStr account}
'';

  configFile = mailAccounts: ''
    ${cfg.extraConfig}

    ${concatStringsSep "\n" (map accountStr mailAccounts)}
  '';
in
{

  options = {
    programs.msmtp = {
      enable = mkEnableOption "Msmtp";

      offlineSendMethod = mkOption {
        type = types.enum [ "none" "native" ];
        default = "native";
        description = ''
          How to deal with messages in absence of connectivity.
          See <link xlink:href="https://github.com/pazz/alot/wiki/Tips,-Tricks-and-other-cool-Hacks"/>
          for a list of options.
        '';
      };

      sendCommand = mkOption {
        readOnly = true;
        type = types.unspecified;
        default = sendMsmtpCommand ;
        description = "Command to send a message via msmtp";
      };

      extraConfig = mkOption {
        type = types.lines;
        default = "";
        description = ''
          Extra configuration lines to add to .msmtprc.
          See <link xlink:href="https://marlam.de/msmtp/msmtprc.txt"/> for examples.
        '';
      };
    };

    accounts.email.accounts = mkOption {
      options = [
        {
          msmtp = {
            enable = mkEnableOption "msmtp as sendmail";
          };
        }
      ];
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.msmtp ];

    xdg.configFile."msmtp/config".text = configFile msmtpAccounts;

    home.activation.msmtpCreateQueueFolder = dag.entryAfter [ "linkGeneration" ] ''
      mkdir -p ${config.xdg.dataHome}/msmtp
    '';

    home.sessionVariables =  {
      MSMTP_QUEUE = "${config.xdg.dataHome}/msmtp/";
      MSMTP_LOG = "${config.xdg.dataHome}/msmtp.log";
    };
  };
}
