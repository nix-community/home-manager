{
  lib,
  pkgs,
  hmConfig,
}:

let
  commonOptions = {

    devices = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = ''
        Full input device paths (Linux: {file}`/dev/input/by-id/…`, or a
        {option}`symlinkPath` from another keyboard) or device name substrings
        (macOS). Prefer {option}`deviceIds` for physical keyboards on Linux.
        An empty list lets kanata auto-detect all keyboards.
      '';
    };

    deviceIds = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [ "usb-PFU_Limited_HHKB_Professional_JP-event-kbd" ];
      description = ''
        Physical keyboard IDs as listed under {file}`/dev/input/by-id/`.
        The {file}`/dev/input/by-id/` prefix is added automatically.
        Linux only; ignored on macOS (use {option}`devices` there instead).
      '';
    };

    continueIfNoDevsFound = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Do not exit when no matching input devices are found at startup.
        Useful when the keyboard may not be connected yet (e.g. Tier 2
        configs waiting for Tier 1 virtual-device symlinks).
      '';
    };

    processUnmappedKeys = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Pass keys not listed in `defsrc` through unchanged. Enable on
        Tier 1 remap keyboards so only the bridging keys are intercepted.
      '';
    };

    defsrc = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [
        "caps"
        "a"
        "s"
        "d"
        "f"
      ];
      description = "Keys to intercept, as kanata key names. Rendered as a `(defsrc …)` block.";
    };

    layers = lib.mkOption {
      type = lib.types.attrsOf (lib.types.listOf lib.types.str);
      default = { };
      example = lib.literalExpression ''{ base = [ "lctl" "a" "s" "d" "f" ]; }'';
      description = ''
        Layer definitions as `layer-name TO list-of-actions`. Each entry
        becomes a `(deflayer name …)` block. Every layer must have the same
        number of entries as `defsrc`. Layers are emitted in alphabetical
        key order; name your base layer so it sorts first (e.g. `"base"`
        or `"_default"`).
      '';
    };

    extraConfig = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = ''
        Raw kanata configuration appended after the generated blocks. Use
        this for `defalias`, `defvar`, `deffakekeys`, etc.
      '';
    };

    extraDefCfg = lib.mkOption {
      type = lib.types.lines;
      default = "";
      example = "danger-enable-cmd yes";
      description = "Extra lines placed inside the `(defcfg …)` block.";
    };

    port = lib.mkOption {
      type = lib.types.nullOr lib.types.port;
      default = null;
      example = 7070;
      description = "TCP port for the kanata command server. `null` disables it (default).";
    };

    extraArgs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Extra command-line arguments passed verbatim to kanata.";
    };

    configFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = ''
        Path to a kanata configuration file. When set explicitly the
        generated config (from `defsrc`, `layers`, `extraConfig`, etc.)
        is ignored. When `null` (the default), a config file is generated
        from the other options and written to
        {file}`$XDG_CONFIG_HOME/kanata/<name>.kbd`.
      '';
    };

  };

in
{
  keyboardSubmodule = lib.types.submodule (
    { name, ... }:
    {
      options = commonOptions // {

        symlinkPath = lib.mkOption {
          type = lib.types.str;
          readOnly = true;
          default = "${hmConfig.xdg.stateHome}/kanata/${name}";
          defaultText = lib.literalMD "`\${config.xdg.stateHome}/kanata/<name>`";
          description = ''
            Path where kanata writes the virtual uinput device symlink on
            Linux (via `--symlink-path`). Known at evaluation time, so it
            can be referenced in {option}`services.kanata.default.devices`
            or another keyboard's `devices` list.
          '';
        };

      };
    }
  );

  defaultSubmodule = lib.types.submodule (_: {
    options = commonOptions // {

      devices = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = lib.optionals pkgs.stdenv.isLinux (
          lib.mapAttrsToList (_: kbd: kbd.symlinkPath) hmConfig.services.kanata.keyboards
        );
        defaultText = lib.literalMD "All `keyboards.*.symlinkPath` values (Linux only).";
        description = ''
          Full input device paths to monitor. Defaults to the virtual-device
          symlinks of all {option}`keyboards` entries on Linux, which is the
          correct setup for a Tier 2 config in a tiered multi-keyboard pipeline.

          Override this if you need to monitor additional or different devices.
        '';
      };

      symlinkPath = lib.mkOption {
        type = lib.types.str;
        readOnly = true;
        default = "${hmConfig.xdg.stateHome}/kanata/default";
        defaultText = lib.literalMD "`\${config.xdg.stateHome}/kanata/default`";
        description = ''
          Path where kanata writes the virtual uinput device symlink on Linux.
          Provided for symmetry; rarely needed since `default` is Tier 2.
        '';
      };

    };
  });
}
