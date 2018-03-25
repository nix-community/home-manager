{ config, lib, pkgs, ... }:

with lib;
with import ../lib/dag.nix { inherit lib; };

let

  cfg = config.programs.msmtp;

  sendMsmtpCommand = account:
      if cfg.offlineSendMethod == "native" then
        "${pkgs.msmtp}/bin/msmtp-queue --account=${account.name} -t"
      # "none"
      else
        "${pkgs.msmtp}/bin/msmtp --account=${account.name} -t";

  # TODO support passwordeval if needed
  accountStr = {userName, address, realname, ...} @ account:
    ''
defaults
tls on
tls_trust_file ${config.mail.certificate}
logfile ~/.msmtp.log

account ${account.name}
host ${account.sendHost}
from ${address}
auth on
user ${account.userName}
tls_certcheck off
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
      home.file.".msmtprc".source =  configFile config.mail.accounts;
    }
  ];
}
