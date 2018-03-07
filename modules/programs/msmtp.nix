{ config, lib, pkgs, ... }:

with lib;
with import ../lib/dag.nix { inherit lib; };

let

  cfg = config.programs.msmtp;
  sendCommand = account:
    "msmtp --account=${account.name} -t";

  accountStr = {userName, address, realname, ...} @ account:
    ''
defaults
tls on
#tls_trust_file /etc/ssl/certs/ca-certificates.crt
logfile ~/.msmtp.log

account ${account.name}
host ${account.sendHost}
from ${address}
auth on
user ${account.userName}
tls_certcheck off
port 587

      '';

  # ${concatStringsSep "\n" (mapAttrsToList assignStr assigns)}
  configFile = mailAccounts: pkgs.writeText "msmtp" (  ''

    ${concatStringsSep "\n" (map accountStr mailAccounts)}

    # TODO fix pick one
    account default : gmail
  '' 
  # + cfg.extraConfig
  );

in

{

  options = {
    programs.msmtp = {
      enable = mkEnableOption "Msmtp";

      extraConfig = mkOption {
        type = types.lines;
        default = "";
        description = "Extra configuration lines to add to .msmtprc.";
      };
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.msmtp ];

    # create folder where to store mails
      # home.activation.createAlotConfig = dagEntryBefore [ "linkGeneration" ] ''
      #   #     "${config.xdg.configHome}/i3/config"; then
      # '';

      # ca s appelle notmuchrc plutot
      home.file.".msmtprc".source = configFile config.home.mailAccounts;
      # ''
      # '';
  };
}
