{ config, pkgs, lib, ... }:

with lib;
let

  cfg = config.i18n.inputMethod;

  gtk2Cache = pkgs.runCommandLocal "gtk2-immodule.cache" {
    buildInputs = [ pkgs.gtk2 cfg.package ];
  } ''
    mkdir -p $out/etc/gtk-2.0/
    GTK_PATH=${cfg.package}/lib/gtk-2.0/ \
      gtk-query-immodules-2.0 > $out/etc/gtk-2.0/immodules.cache
  '';

  gtk3Cache = pkgs.runCommandLocal "gtk3-immodule.cache" {
    buildInputs = [ pkgs.gtk3 cfg.package ];
  } ''
    mkdir -p $out/etc/gtk-3.0/
    GTK_PATH=${cfg.package}/lib/gtk-3.0/ \
      gtk-query-immodules-3.0 > $out/etc/gtk-3.0/immodules.cache
  '';

in {
  imports = [ ./fcitx5.nix ./hime.nix ./kime.nix ./nabi.nix ./uim.nix ];

  options.i18n = {
    inputMethod = {
      enabled = mkOption {
        type = types.nullOr
          (types.enum [ "fcitx" "fcitx5" "nabi" "uim" "hime" "kime" ]);
        default = null;
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

      package = mkOption {
        internal = true;
        type = types.nullOr types.path;
        default = null;
        description = ''
          The input method method package.
        '';
      };
    };
  };

  config = mkIf (cfg.enabled != null) {
    assertions = [
      (hm.assertions.assertPlatform "i18n.inputMethod" pkgs platforms.linux)
      {
        assertion = cfg.enabled != "fcitx";
        message = "fcitx has been removed, please use fcitx5 instead";
      }
    ];

    home.packages = [ cfg.package gtk2Cache gtk3Cache ];
  };

  meta.maintainers = with lib; [ hm.maintainers.kranzes ];
}
