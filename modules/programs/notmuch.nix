{ config, lib, pkgs, ... }:

with lib;
# with import ../lib/dag.nix { inherit lib; };

let

  cfg = config.programs.notmuch;

in

{
# TODO per account specifics
# [new]
# tags=unread;inbox;
# ignore=

  options = {
    programs.notmuch = {
      enable = mkEnableOption "Notmuch";

    };
  };




  let 
  configFile = pkgs.writeText "notmuch.conf" ((if cfg.config != null then with cfg.config; ''

      [database]
      path=${home}
[user]
name=matt
primary_email=mattator@gmail.com
# other_email=

[new]
tags=unread;inbox;
ignore=

[search]
exclude_tags=deleted;spam;

[maildir]
synchronize_flags=true
    font pango:${concatStringsSep ", " fonts}
    floating_modifier ${floating.modifier}
    new_window ${if window.titlebar then "normal" else "pixel"} ${toString window.border}
    new_float ${if floating.titlebar then "normal" else "pixel"} ${toString floating.border}
    force_focus_wrapping ${if focus.forceWrapping then "yes" else "no"}
    focus_follows_mouse ${if focus.followMouse then "yes" else "no"}
    focus_on_window_activation ${focus.newWindow}

    client.focused ${colorSetStr colors.focused}
  '' else "") + "\n" );
    # ${keybindingsStr keybindings}
    # ${concatStringsSep "\n" (mapAttrsToList modeStr modes)}
    # ${concatStringsSep "\n" (mapAttrsToList assignStr assigns)}
    # ${concatStringsSep "\n" (map barStr bars)}
    # ${optionalString (gaps != null) gapsStr}
    # ${concatStringsSep "\n" (map floatingCriteriaStr floating.criteria)}
    # ${concatStringsSep "\n" (map startupEntryStr startup)}

in


  config = mkIf cfg.enable {
    home.packages = [ notmuch ];

    # create folder where to store mails
      home.activation.createMailStore = dagEntryBefore [ "linkGeneration" ] ''
        echo 'hello world, notmuch link activation'
        # if ! cmp --quiet \
        #     "${configFile}" \
        #     "${config.xdg.configHome}/i3/config"; then
        #   i3Changed=1
        # fi
      '';

      xdg.configFile."notmuch/config".source = configFile;
      # ''
      # '';
  };
}


