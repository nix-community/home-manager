{ config, lib, pkgs, ... }:

with lib;
with import ../lib/dag.nix { inherit lib; };

let

  cfg = config.programs.alot;

  # alot_hooks=
  # TODO should depend on MTA but for now we have only msmtp
  sendCommand = config.programs.msmtp.sendCommand;
    
  accountStr = {name,userName, address, realname, ...} @ account:
    ''
      [[${name}]]
      address=${address}
      realname=${realname}

      sendmail_command = ${sendCommand account}
      '';

    bindingStr = ''
      # TODO if offlineimap configured, run offlineimap
      G = call hooks.getmail(ui)
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
initial_command = search tag:inbox AND NOT tag:killed;
input_timeout=0.3
# list of adresses
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

      # programs.zsh.shellAliases = lib.optional cfg.createAliases 
      # # (map {} )
      # (zipAttrsWith (account: )  home.mail.accounts)
      # ;

      # ca s appelle notmuchrc plutot
      xdg.configFile."alot/config".source = configFile config.mail.accounts;

      xdg.configFile."alot/hm_hooks".text = ''
        # Home-manager custom hooks
        '';
  };
}

