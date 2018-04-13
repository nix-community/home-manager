{ config, lib, pkgs, ... } @ top:

with lib;
with builtins;
# with import ../lib/dag.nix { inherit lib; };

let

  cfg = config.programs.msmtp;

  # TODO pass a custom config with  
  sendMsmtpCommand = account:
      if cfg.offlineSendMethod == "native" then
        # TODO check msmtp-queue sends the mail
        "${pkgs.msmtp}/bin/msmtpq -C $XDG_CONFIG_HOME/msmtp/config --account=${account.name} -t"
      # "none"
      else
        "${pkgs.msmtp}/bin/msmtp $XDG_CONFIG_HOME/msmtp/config --account=${account.name} -t";

  # TODO support passwordeval if needed
  # TODO restore 
  accountStr = {userName, address, realname, ...} @ account:
    ''
defaults
tls on
tls_trust_file ${config.mail.certificateStore}
logfile ~/.msmtp.log

account ${account.name}
host ${account.sendHost}
from ${address}
auth on
user ${account.userName}
tls_certcheck on
port 587
      '';

    # TODO fix pick one
    # account default : gmail
  configFile = mailAccounts: pkgs.writeText "msmtp" (  ''

    ${concatStringsSep "\n" (map accountStr mailAccounts)}
  '' 
  );

in

{

  options.programs.msmtp = {
    enable = mkEnableOption "Msmtp";

    offlineSendMethod = mkOption {
      # https://wiki.archlinux.org/index.php/Msmtp#Using_msmtp_offline
      # see for a list of methodds 
      # https://github.com/pazz/alot/wiki/Tips,-Tricks-and-other-cool-Hacks
      type = types.enum [ "none" "native" ];
      default = "native";
      description = "Extra configuration lines to add to .msmtprc.";
    };


    sendCommand = mkOption {
      # https://wiki.archlinux.org/index.php/Msmtp#Using_msmtp_offline
      # see for a list of methodds 
      # https://github.com/pazz/alot/wiki/Tips,-Tricks-and-other-cool-Hacks
      # type = types.str;
      default = sendMsmtpCommand ;
      description = "Extra configuration lines to add to .msmtprc.";
    };


    extraConfig = mkOption {
      type = types.lines;
      default = "";
      description = "Extra configuration lines to add to .msmtprc.";
    };
  };

  config = mkMerge [
    (mkIf cfg.enable { home.packages = [ pkgs.msmtp ]; })
    {
      xdg.configFile."msmtp/config".source =  configFile config.mail.accounts;
      # TODO wrap msmtpq with  MSMTP_QUEUE/MSMTP_LOG set instead
      home.sessionVariables =  {
        MSMTP_QUEUE = "$XDG_DATA_HOME/msmtp/";
        MSMTP_LOG = "$XDG_DATA_HOME/msmtp/log";
      };
      # getXdgDir
      xdg.dataFile."msmtp/fake".text = "";
    }
    (mkIf (cfg.offlineSendMethod  == "native" ) {
      # home.packages = [ pkgs.msmtp ]; 
      # TODO launch a service
    })
  ];
}
