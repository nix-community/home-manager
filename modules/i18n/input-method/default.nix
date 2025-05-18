{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.i18n.inputMethod;

  allowedTypes = lib.types.enum [
    "fcitx"
    "fcitx5"
    "nabi"
    "uim"
    "hime"
    "kime"
  ];

  gtk2Cache =
    pkgs.runCommandLocal "gtk2-immodule.cache"
      {
        buildInputs = [
          pkgs.gtk2
          cfg.package
        ];
      }
      ''
        mkdir -p $out/etc/gtk-2.0/
        GTK_PATH=${cfg.package}/lib/gtk-2.0/ \
          gtk-query-immodules-2.0 > $out/etc/gtk-2.0/immodules.cache
      '';

  gtk3Cache =
    pkgs.runCommandLocal "gtk3-immodule.cache"
      {
        buildInputs = [
          pkgs.gtk3
          cfg.package
        ];
      }
      ''
        mkdir -p $out/etc/gtk-3.0/
        GTK_PATH=${cfg.package}/lib/gtk-3.0/ \
          gtk-query-immodules-3.0 > $out/etc/gtk-3.0/immodules.cache
      '';
in
{
  imports = [
    ./fcitx5.nix
    ./hime.nix
    ./kime.nix
    ./nabi.nix
    ./uim.nix
  ];

  options.i18n = {
    inputMethod = {
      enable = lib.mkEnableOption "an additional input method type" // {
        default = cfg.enabled != null;
        defaultText = lib.literalMD "`true` if the deprecated option `enabled` is set, false otherwise";
      };

      enabled = lib.mkOption {
        type = lib.types.nullOr allowedTypes;
        default = null;
        example = "fcitx5";
        description = "Deprecated - use `type` and `enable = true` instead";
      };

      type = lib.mkOption {
        type = lib.types.nullOr allowedTypes;
        default = cfg.enabled;
        defaultText = lib.literalMD "The value of the deprecated option `enabled`, defaulting to null";
        example = "fcitx5";
        description = ''
          Select the enabled input method. Input methods are software to input
          symbols that are not available on standard input devices.

          Input methods are especially used to input Chinese, Japanese and
          Korean characters.

          Currently the following input methods are available in Home Manager:

          `fcitx5`
          : A customizable lightweight input method.
            The next generation of fcitx.
            Addons (including engines, dictionaries, skins) can be added using
            [](#opt-i18n.inputMethod.fcitx5.addons).

          `nabi`
          : A Korean input method based on XIM. Nabi doesn't support Qt 5.

          `uim`
          : The "universal input method" is a library with an XIM bridge.
            uim mainly supports Chinese, Japanese and Korean.

          `hime`
          : An extremely easy-to-use input method framework.

          `kime`
          : A Korean IME.
        '';
      };

      package = lib.mkOption {
        internal = true;
        type = lib.types.nullOr lib.types.path;
        default = null;
        description = ''
          The input method method package.
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "i18n.inputMethod" pkgs lib.platforms.linux)
      {
        assertion = cfg.enabled != "fcitx";
        message = "fcitx has been removed, please use fcitx5 instead";
      }
    ];

    warnings =
      lib.optional (cfg.enabled != null)
        "i18n.inputMethod.enabled will be removed in a future release. Please use .type, and .enable = true instead";

    home.packages = [
      cfg.package
      gtk2Cache
      gtk3Cache
    ];
  };

  meta.maintainers = [
    lib.hm.maintainers.kranzes
    lib.maintainers.awwpotato
  ];
}
