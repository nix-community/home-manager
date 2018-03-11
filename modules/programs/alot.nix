{ config, lib, pkgs, ... }:

with lib;
with import ../lib/dag.nix { inherit lib; };

let

  cfg = config.programs.alot;
  sendCommand = account:
    "msmtp --account=${account.name} -t";

  # alot_hooks=

  accountStr = {name,userName, address, realname, ...} @ account:
    ''
      [[${name}]]
      address=${address}
      realname=${realname}

      sendmail_command = ${sendCommand account}
      '';

  # ${concatStringsSep "\n" (mapAttrsToList assignStr assigns)}
  # should we set themes_dir as well ?
# alot hooks use default for now
# hooksfile = ${xdg.configFile."alot/hm_hooks"}
  configFile = mailAccounts: pkgs.writeText "alot.conf" (  ''

theme = "solarized_dark"
auto_remove_unread = True
ask_subject = False
#auto_replyto_mailinglist
# launch sequence of commands separated by ;
initial_command = search tag:inbox AND NOT tag:killed AND NOT tag:ietf ; 
input_timeout=0.3
# list of adresses
mailinglists = lisp@ietf.org, taps@ietf.org 
prefer_plaintext = True
  [accounts]

    ${concatStringsSep "\n" (map accountStr mailAccounts)}

  '' 
  );

in

{

  options = {
    programs.alot = {
      enable = mkEnableOption "Alot";

      createAliases = mkOption {
        type = types.bool;
        default = false;
        description = "create alias alot_\${account.name}";
      };
      extraConfig = mkOption {
        type = types.lines;
        default = "";
        description = "Extra configuration lines to add to ~/.config/alot/config.";
      };
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

      xdg.configFile."alot/hm_hooks".text = ''
        # Home-manager custom hooks
        '';
  };
}

