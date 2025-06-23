{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib)
    mkOption
    types
    literalExpression
    ;

  cfg = config.services.sxhkd;

  keybindingsStr = lib.concatStringsSep "\n" (
    lib.mapAttrsToList (
      hotkey: command:
      lib.optionalString (command != null) ''
        ${hotkey}
          ${command}
      ''
    ) cfg.keybindings
  );

in
{
  imports = [
    (lib.mkRemovedOptionModule [
      "services"
      "sxhkd"
      "extraPath"
    ] "This option is no longer needed and can be removed.")
  ];

  options.services.sxhkd = {
    enable = lib.mkEnableOption "simple X hotkey daemon";

    package = lib.mkPackageOption pkgs "sxhkd" {
      extraDescription = "containing the sxhkd executable";
    };

    extraOptions = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Command line arguments to invoke {command}`sxhkd` with.";
      example = literalExpression ''[ "-m 1" ]'';
    };

    keybindings = mkOption {
      type = types.attrsOf (
        types.nullOr (
          types.oneOf [
            types.str
            types.path
          ]
        )
      );
      default = { };
      description = "An attribute set that assigns hotkeys to commands.";
      example = literalExpression ''
        {
          "super + shift + {r,c}" = "i3-msg {restart,reload}";
          "super + {s,w}"         = "i3-msg {stacking,tabbed}";
          "super + F1"            = pkgs.writeShellScript "script" "echo $USER";
        }
      '';
    };

    extraConfig = mkOption {
      default = "";
      type = types.lines;
      description = "Additional configuration to add.";
      example = literalExpression ''
        super + {_,shift +} {1-9,0}
          i3-msg {workspace,move container to workspace} {1-10}
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.sxhkd" pkgs lib.platforms.linux)
    ];

    home.packages = [ cfg.package ];

    xdg.configFile."sxhkd/sxhkdrc".text = lib.concatStringsSep "\n" [
      keybindingsStr
      cfg.extraConfig
    ];

    xsession.initExtra =
      let
        sxhkdCommand = "${cfg.package}/bin/sxhkd ${toString cfg.extraOptions}";
      in
      ''
        systemctl --user stop sxhkd.scope 2> /dev/null || true
        systemd-cat -t sxhkd systemd-run --user --scope --property=OOMPolicy=continue -u sxhkd ${sxhkdCommand} &
      '';
  };
}
