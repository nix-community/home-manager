{ config, lib, pkgs, ... }:

with lib;
with import ../lib/dag.nix { inherit lib; };

let

  cfg = config.programs.msmtp;
  sendCommand = account:
    "msmtp --account=${account.userName} -t";

  accountStr = {userName, address, realname, ...} @ account:
    ''
      [[${userName}]]
      address=${address}
      realname=${realname}

      sendmail_command = ${sendCommand account}

account gmail
host smtp.gmail.com
from username@gmail.com
auth on
user username@gmail.com
tls_certcheck off
port 587
      '';

  # ${concatStringsSep "\n" (mapAttrsToList assignStr assigns)}
  configFile = mailAccounts: pkgs.writeText "msmtp.conf" (  ''
  [accounts]

    ${concatStringsSep "\n" (map accountStr mailAccounts)}

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
      xdg.configFile.".msmtprc".source = configFile config.home.mailAccounts;
      # ''
      # '';
  };
}
