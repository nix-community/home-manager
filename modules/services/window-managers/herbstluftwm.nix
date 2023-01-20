{ config, lib, pkgs, ... }:

let

  cfg = config.xsession.windowManager.herbstluftwm;

  renderValue = val:
    if lib.isBool val then
      if val then "true" else "false"
    else
      lib.escapeShellArg val;

  renderSettings = settings:
    lib.concatStringsSep "\n" (lib.mapAttrsToList
      (name: value: "herbstclient set ${name} ${renderValue value}") settings);

  renderKeybinds = keybinds:
    lib.concatStringsSep "\n"
    (lib.mapAttrsToList (key: cmd: "herbstclient keybind ${key} ${cmd}")
      keybinds);

  renderMousebinds = mousebinds:
    lib.concatStringsSep "\n"
    (lib.mapAttrsToList (btn: cmd: "herbstclient mousebind ${btn} ${cmd}")
      mousebinds);

  renderRules = rules:
    lib.concatStringsSep "\n" (map (rule: "herbstclient rule ${rule}") rules);

  settingType = lib.types.oneOf [ lib.types.bool lib.types.int lib.types.str ];

  escapedTags = map lib.escapeShellArg cfg.tags;

in {
  meta.maintainers = [ lib.hm.maintainers.olmokramer ];

  options.xsession.windowManager.herbstluftwm = {
    enable = lib.mkEnableOption "herbstluftwm window manager";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.herbstluftwm;
      defaultText = lib.literalExpression "pkgs.herbstluftwm";
      description = ''
        Package providing the <command>herbstluftwm</command> and
        <command>herbstclient</command> commands.
      '';
    };

    settings = lib.mkOption {
      type = lib.types.attrsOf settingType;
      default = { };
      example = lib.literalExpression ''
        {
          gapless_grid = false;
          window_border_width = 1;
          window_border_active_color = "#FF0000";
        }
      '';
      description = "Herbstluftwm settings.";
    };

    keybinds = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      example = lib.literalExpression ''
        {
          Mod4-o = "split right";
          Mod4-u = "split bottom";
        }
      '';
      description = "Herbstluftwm keybinds.";
    };

    mousebinds = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      example = lib.literalExpression ''
        {
          Mod4-B1 = "move";
          Mod4-B3 = "resize";
        }
      '';
      description = "Herbstluftwm mousebinds.";
    };

    rules = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = lib.literalExpression ''
        [
          "windowtype~'_NET_WM_WINDOW_TYPE_(DIALOG|UTILITY|SPLASH)' focus=on pseudotile=on"
          "windowtype~'_NET_WM_WINDOW_TYPE_(NOTIFICATION|DOCK|DESKTOP)' manage=off"
        ]
      '';
      description = "Herbstluftwm rules.";
    };

    tags = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = lib.literalExpression ''
        [ "work" "browser" "music" "gaming" ]
      '';
      description = "Tags to create on startup.";
    };

    extraConfig = lib.mkOption {
      type = lib.types.lines;
      default = "";
      example = ''
        herbstclient set_layout max
        herbstclient detect_monitors
      '';
      description = ''
        Extra configuration lines to add verbatim to
        <filename>$XDG_CONFIG_HOME/herbstluftwm/autostart</filename>.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "xsession.windowManager.herbstluftwm"
        pkgs lib.platforms.linux)
    ];

    home.packages = [ cfg.package ];

    xsession.windowManager.command = "${cfg.package}/bin/herbstluftwm --locked";

    xdg.configFile."herbstluftwm/autostart".source =
      pkgs.writeShellScript "herbstluftwm-autostart" ''
        shopt -s expand_aliases

        # shellcheck disable=SC2142
        alias herbstclient='set -- "$@" ";"'
        set --

        herbstclient emit_hook reload

        # Reset everything.
        herbstclient attr theme.tiling.reset 1
        herbstclient attr theme.floating.reset 1
        herbstclient keyunbind --all
        herbstclient mouseunbind --all
        herbstclient unrule --all

        ${renderSettings cfg.settings}

        ${lib.optionalString (cfg.tags != [ ]) ''
          for tag in ${lib.concatStringsSep " " escapedTags}; do
            herbstclient add "$tag"
          done

          if ${cfg.package}/bin/herbstclient object_tree tags.by-name.default &>/dev/null; then
            herbstclient use ${lib.head escapedTags}
            herbstclient merge_tag default ${lib.head escapedTags}
          fi
        ''}

        ${renderKeybinds cfg.keybinds}

        ${renderMousebinds cfg.mousebinds}

        ${renderRules cfg.rules}

        ${cfg.extraConfig}

        herbstclient unlock

        ${cfg.package}/bin/herbstclient chain ";" "$@"
      '';
  };
}
