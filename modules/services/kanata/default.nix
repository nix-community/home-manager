{
  config,
  lib,
  pkgs,
  ...
}:

let
  hmConfig = config;
  cfg = config.services.kanata;

  kanataLib = import ./lib.nix { inherit lib pkgs; };
  inherit (kanataLib) mkKanataConfigText allDevices;
  inherit
    (import ./submodules.nix {
      inherit
        lib
        pkgs
        hmConfig
        ;
    })
    keyboardSubmodule
    defaultSubmodule
    ;

  allKeyboards = cfg.keyboards // lib.optionalAttrs (cfg.default != null) { inherit (cfg) default; };
in
{
  meta.maintainers = with lib.maintainers; [ philocalyst ];

  imports = [
    ./linux.nix
    ./darwin.nix
  ];

  options.services.kanata = {

    enable = lib.mkEnableOption "kanata, a software keyboard remapper";

    package = lib.mkPackageOption pkgs "kanata" {
      extraDescription = ''
        ::: {.note}
        Use `pkgs.kanata-with-cmd` if `danger-enable-cmd yes` appears in any
        keyboard's {option}`extraDefCfg`.
        :::
      '';
    };

    keyboards = lib.mkOption {
      type = lib.types.attrsOf keyboardSubmodule;
      default = { };
      description = ''
        Tier 1 per-keyboard remap configurations, keyed by an arbitrary name.
        Each entry runs as its own kanata service instance and exposes a
        virtual uinput device at {option}`symlinkPath`.

        On Linux, use {option}`deviceIds` to specify physical keyboards by the
        ID portion of their {file}`/dev/input/by-id/` path:

        ```nix
        services.kanata.keyboards.remap_HHKB = {
          deviceIds = [ "usb-PFU_Limited_HHKB-event-kbd" ];
          processUnmappedKeys = true;
          defsrc = [ "muhenkan" "henkan" "kana" ];
          layers.base = [ "f13" "f14" "f15" ];
        };
        ```

        ::: {.note}
        On Linux the user must belong to the `input` and `uinput` groups.
        In NixOS, set `hardware.uinput.enable = true`.
        :::

        ::: {.note}
        No udev rule or restart-on-hotplug unit is needed: kanata's own Linux
        input backend watches `/dev/input` (via inotify) and automatically
        reopens a configured device -- including a {option}`symlinkPath` a
        Tier 1 keyboard depends on -- if it disappears and later reappears
        under the same path, without the service ever exiting or restarting.
        `Restart = "on-failure"` on the generated systemd unit is only a
        crash-recovery safety net, not part of hot-plug handling.
        :::
      '';
    };

    default = lib.mkOption {
      type = lib.types.nullOr defaultSubmodule;
      default = null;
      description = ''
        Tier 2 main kanata configuration. Runs as a dedicated service
        named `kanata-default`.

        On Linux, {option}`devices` defaults to the {option}`symlinkPath`
        of every entry in {option}`keyboards`, so this config automatically
        reads from all Tier 1 virtual devices without any manual wiring:

        ```nix
        services.kanata = {
          enable = true;

          keyboards.remap_HHKB = {
            deviceIds = [ "usb-PFU_Limited_HHKB-event-kbd" ];
            processUnmappedKeys = true;
            defsrc = [ "muhenkan" "henkan" "kana" ];
            layers.base = [ "f13" "f14" "f15" ];
          };

          default = {
            defsrc = [ "caps" "a" "s" "d" "f" "f13" "f14" "f15" ];
            layers.base = [ "@cap" "a" "s" "d" "f" "esc" "ret" "spc" ];
            extraConfig = "(defalias cap (tap-hold 200 200 caps lctl))";
          };
        };
        ```

        Set to `null` (the default) if you do not need a Tier 2 config.
      '';
    };

  };

  config = lib.mkIf cfg.enable {

    assertions = [
      {
        assertion = cfg.keyboards != { } || cfg.default != null;
        message = "services.kanata: define at least one keyboard in `keyboards` or set `default`.";
      }
      {
        assertion = lib.all (n: !(lib.hasInfix " " n)) (lib.attrNames cfg.keyboards);
        message = "services.kanata: keyboard names must not contain spaces.";
      }
      {
        # kanata's `defsrc`/`deflayer` grammar has no quoting mechanism for
        # names/keys
        assertion =
          let
            hasBadChar =
              s:
              lib.any (c: lib.hasInfix c s) [
                " "
                "\t"
                "\n"
                "("
                ")"
                "\""
              ];
          in
          lib.all (kbd: !(lib.any hasBadChar (kbd.defsrc ++ lib.attrNames kbd.layers))) (
            lib.attrValues allKeyboards
          );
        message = ''
          services.kanata: `defsrc` key names and `layers` names must each be
          a single bare token with no whitespace, parentheses, or quotes
        '';
      }
      {
        assertion = lib.all (kbd: lib.all (d: !(lib.hasInfix "\"" d)) (allDevices kbd)) (
          lib.attrValues allKeyboards
        );
        message = ''
          services.kanata: `devices`/`deviceIds` entries must not contain a
          literal `"` character -- kanata's config string syntax has no
          escape mechanism for embedded quotes.
        '';
      }
    ];

    home.packages = [ cfg.package ];

    xdg.configFile = lib.mapAttrs' (
      name: kbd:
      lib.nameValuePair "kanata/${name}.kbd" {
        text = mkKanataConfigText name kbd;
      }
    ) (lib.filterAttrs (_: kbd: kbd.configFile == null) allKeyboards);

  };
}
