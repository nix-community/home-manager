{ config, lib, pkgs, ... }:

with lib;
with import ../lib/dag.nix { inherit lib; };

let

  cfg = config.programs.alot;
  sendCommand = account:
    "msmtp --account=${account.userName} -t";

  accountStr = {userName, address, realname, ...} @ account:
    ''
      [[${userName}]]
      address=${address}
      realname=${realname}

      sendmail_command = ${sendCommand account}
      '';

  # ${concatStringsSep "\n" (mapAttrsToList assignStr assigns)}
  configFile = mailAccounts: pkgs.writeText "alot.conf" (  ''
  [accounts]

    ${concatStringsSep "\n" (map accountStr mailAccounts)}

  '' 
  # + cfg.extraConfig
  );

in

{

  options = {
    programs.alot = {
      enable = mkEnableOption "Alot";
    };

    extraConfig = mkOption {
      type = types.lines;
      default = "";
      description = "Extra configuration lines to add to ~/.config/alot/config.";
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.alot ];

    # create folder where to store mails
      # home.activation.createAlotConfig = dagEntryBefore [ "linkGeneration" ] ''
      #   #     "${config.xdg.configHome}/i3/config"; then
      # '';

      # ca s appelle notmuchrc plutot
      xdg.configFile."alot/config".source = configFile config.home.mailAccounts;
      # ''
      # '';
  };
}

