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
  imports =
    [ ./fcitx.nix ./fcitx5.nix ./hime.nix ./kime.nix ./nabi.nix ./uim.nix ];

  options.i18n = {
    inputMethod = {
      enabled = mkOption {
        type = types.nullOr
          (types.enum [ "fcitx" "fcitx5" "nabi" "uim" "hime" "kime" ]);
        default = null;
        example = "fcitx";
        description = ''
          Select the enabled input method. Input methods is a software to input
          symbols that are not available on standard input devices.
          </para><para>
          Input methods are specially used to input Chinese, Japanese and Korean
          characters.
          </para><para>
          Currently the following input methods are available in Home Manager:

          <variablelist>
          <varlistentry>
            <term><literal>fcitx</literal></term>
            <listitem><para>
              A customizable lightweight input method
              extra input engines can be added using
              <literal>i18n.inputMethod.fcitx.engines</literal>.
            </para></listitem>
          </varlistentry>
          <varlistentry>
            <term><literal>fcitx5</literal></term>
            <listitem><para>
              The next generation of fcitx,
              addons (including engines, dictionaries, skins) can be added using
              <literal>i18n.inputMethod.fcitx5.addons</literal>.
            </para></listitem>
          </varlistentry>
          <varlistentry>
            <term><literal>nabi</literal></term>
            <listitem><para>
              A Korean input method based on XIM. Nabi doesn't support Qt 5.
            </para></listitem>
          </varlistentry>
          <varlistentry>
            <term><literal>uim</literal></term>
            <listitem><para>
              The universal input method, is a library with a XIM bridge.
              uim mainly support Chinese, Japanese and Korean.
            </para></listitem>
          </varlistentry>
          <varlistentry>
            <term><literal>hime</literal></term>
            <listitem><para>An extremely easy-to-use input method framework.</para></listitem>
          </varlistentry>
          <varlistentry>
            <term><literal>kime</literal></term>
            <listitem><para>A Korean IME.</para></listitem>
          </varlistentry>
          </variablelist>
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
    ];

    home.packages = [ cfg.package gtk2Cache gtk3Cache ];
  };

  meta.maintainers = with lib; [ hm.maintainers.kranzes ];
}
