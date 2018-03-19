{ config, lib, pkgs, ... }:

with lib;
with import ../lib/dag.nix { inherit lib; };

let

  cfg = config.programs.alot;

  generateNotmuchAlias = account:
  {
    name = "alot-${account.name}";
    value = "${pkgs.alot}/bin/alot -n ${config.xdg.configHome}/notmuch/notmuch_${account.name}"; 
  };
 

  accountStr = {name,userName, address, realname, ...} @ account:
    ''
      [[${name}]]
      address=${address}
      realname=${realname}

      sendmail_command = ${account.mta.sendCommand account}
    '';

    # TODO use
    # bindingStr = ''
    #   # TODO if offlineimap configured, run offlineimap
    #   G = call hooks.getmail(ui)
    # '';

# alot hooks use default for now
# hooksfile = ${xdg.configFile."alot/hm_hooks"}
  configFile = mailAccounts: pkgs.writeText "alot.conf" (''

    theme = ${cfg.theme}
    ${cfg.extraConfig}

    [accounts]

    ${concatStringsSep "\n" (map accountStr mailAccounts)}

  '');

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

      theme = mkOption {
        type = types.enum [ "solarized_dark" ];
        default = "solarized_dark";
        description = "default theme";
      };

      generateAliases = mkOption {
        # type = types.enum [ "solarized_dark" ];
        default = generateNotmuchAlias;
        description = "default theme";
      };


      extraConfig = mkOption {
        type = types.lines;
        default = ''
          auto_remove_unread = True
          ask_subject = False
          # launch sequence of commands separated by ;
          initial_command = search tag:inbox AND NOT tag:killed;
          input_timeout=0.3
          prefer_plaintext = True
        '';
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

