# This module is heavily inspired by the corresponding NixOS module. See
#
#   https://github.com/NixOS/nixpkgs/blob/23.11/nixos/modules/config/fonts/fontconfig.nix

{
  config,
  lib,
  nixosConfig,
  pkgs,
  ...
}:

let

  cfg = config.fonts.fontconfig;

  globalConfig = config;
  fontConfigFileType = lib.types.submodule (
    let
      noteContentOptionsExclusivity = ''
        Note that {option}`source` will be derived from {option}`text` if it is set; with override
        priorities being preserved.  As a consequence, exactly one of {option}`text`, and
        {option}`source` must be set with highest priority.
      '';
    in
    {
      config,
      name,
      options,
      ...
    }:
    {
      options = {
        enable = lib.mkOption {
          description = ''
            Whether this file should be generated. This option allows specific
            files to be disabled.
          '';
          type = lib.types.bool;
          inherit
            (lib.hm.deprecations.mkStateVersionOptionDefault {
              inherit (globalConfig.home) stateVersion;
              since = "26.11";
              optionPath = [
                "fonts"
                "fontconfig"
                "configFile"
                name
                "enable"
              ];
              legacy.value = false;
              current.value = true;
            })
            default
            defaultText
            ;
        };
        label = lib.mkOption {
          description = "Label to use for the name of the config file.";
          default = name;
          defaultText = lib.literalExpression "<name>";
          type = lib.types.str;
        };
        priority = lib.mkOption {
          description = ''
            Determines the order in which configuration files are loaded.

            Must be a value within the range of 0-99, where priority 0 is the
            highest priority and 99 is the lowest.
          '';
          default = 90;
          type = lib.types.ints.between 0 99;
        };
        target = lib.mkOption {
          description = ''
            Path to the target file relative to
            {file}`''${config.xdg.configHome}/fontconfig/conf.d/`.
          '';
          default = "${toString config.priority}-hm-${config.label}.conf";
          defaultText = ''"''${toString config.priority}-hm-''${config.label}.conf"'';
          type = lib.types.nonEmptyStr;
        };
        text = lib.mkOption {
          description = ''
            Verbatim contents of the config file.
          ''
          + noteContentOptionsExclusivity;
          default = null;
          type = with lib.types; nullOr lines;
        };
        source = lib.mkOption {
          description = ''
            Path to the source file.
          ''
          + noteContentOptionsExclusivity;
          type =
            let
              thisOption = lib.showOption [
                "fonts"
                "fontconfig"
                "configFile"
                name
                "source"
              ];
              abortOnNull =
                x:
                if x != null then
                  x
                else
                  abort ''
                    Setting '${thisOption}' to null is not
                    required anymore and disallowed. You can safely remove this definition.
                  '';
            in
            with lib.types;
            coercedTo (nullOr path) abortOnNull path;
        };
      };
      config.source =
        let
          fileName = lib.hm.strings.storeFileName "hm-fontconfig-${config.label}.xml";
          mkTextFile = pkgs.writeText fileName;
        in
        lib.mkIf (config.text != null) (lib.mkDerivedConfig options.text mkTextFile);
    }
  );

in
{
  meta.maintainers = with lib.maintainers; [
    bmrips
    rycee
  ];

  imports = [
    (lib.mkRenamedOptionModule
      [ "fonts" "fontconfig" "enableProfileFonts" ]
      [
        "fonts"
        "fontconfig"
        "enable"
      ]
    )
  ];

  options = {
    fonts.fontconfig = {
      enable = lib.mkOption {
        type = lib.types.bool;
        description = ''
          Whether to enable fontconfig configuration. This will, for example,
          allow fontconfig to discover fonts and configurations installed through
          {var}`home.packages` and {command}`nix-env`.

          If Home Manager is installed as a NixOS submodule and
          {var}`home-manager.useUserPackages` is enabled, this option defaults to the
          value of NixOS' {var}`fonts.fontconfig.enable`.
        '';
        # On NixOS, the per-user directory inside /etc/profiles is not known by
        # fontconfig by default.
        default =
          nixosConfig != null
          && nixosConfig.home-manager.useUserPackages
          && nixosConfig.fonts.fontconfig.enable;
        defaultText = lib.literalExpression ''
          nixosConfig != null
          && nixosConfig.home-manager.useUserPackages
          && nixosConfig.fonts.fontconfig.enable;
        '';
      };

      defaultFonts = {
        monospace = lib.mkOption {
          type = with lib.types; listOf str;
          default = [ ];
          description = ''
            Per-user default monospace font(s). Multiple fonts may be listed in
            case multiple languages must be supported.
          '';
        };

        sansSerif = lib.mkOption {
          type = with lib.types; listOf str;
          default = [ ];
          description = ''
            Per-user default sans serif font(s). Multiple fonts may be listed
            in case multiple languages must be supported.
          '';
        };

        serif = lib.mkOption {
          type = with lib.types; listOf str;
          default = [ ];
          description = ''
            Per-user default serif font(s). Multiple fonts may be listed in
            case multiple languages must be supported.
          '';
        };

        emoji = lib.mkOption {
          type = with lib.types; listOf str;
          default = [ ];
          description = ''
            Per-user default emoji font(s). Multiple fonts may be listed in
            case a font does not support all emoji.

            Note that fontconfig matches color emoji fonts preferentially,
            so if you want to use a black and white font while having
            a color font installed (eg. Noto Color Emoji installed alongside
            Noto Emoji), fontconfig will still choose the color font even
            when it is later in the list.
          '';
        };
      };

      antialiasing = lib.mkOption {
        type = with lib.types; nullOr bool;
        default = null;
        description = "Whether to enable font antialiasing.";
        example = true;
      };
      hinting = lib.mkOption {
        type =
          with lib.types;
          nullOr (enum [
            "none"
            "slight"
            "medium"
            "full"
          ]);
        default = null;
        description = "The font hinting mode.";
        example = "slight";
      };
      subpixelRendering = lib.mkOption {
        type =
          with lib.types;
          nullOr (enum [
            "none"
            "rgb"
            "bgr"
            "vertical-rgb"
            "vertical-bgr"
          ]);
        default = null;
        description = "The sub-pixel rendering mode.";
        example = "rgb";
      };

      configFile = lib.mkOption {
        type = lib.types.attrsOf fontConfigFileType;
        default = { };
        description = ''
          Config files that will be installed to {file}`~/.config/fontconfig/conf.d/`.
        '';
        example = {
          tamzen-disable-antialiasing = {
            enable = true;
            priority = 90;
            text = ''
              <?xml version="1.0"?>
              <!DOCTYPE fontconfig SYSTEM "fonts.dtd">

              <fontconfig>
                <description>Disable anti-aliasing for Tamzen since it is a bitmap font</description>
                <match target="pattern">
                  <test name="family" compare="eq" qual="any">
                    <string>Tamzen</string>
                  </test>
                  <edit name="antialias" mode="assign">
                    <bool>false</bool>
                  </edit>
                </match>
              </fontconfig>
            '';
          };
          commit-mono-options = {
            enable = true;
            priority = 80;
            source = "./resources/fontconfig/commit-mono.conf";
          };
        };

      };

    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      # Make sure that buildEnv creates a real directory path so that we avoid
      # trying to write to a read-only location.
      (pkgs.runCommandLocal "dummy-fc-dir1" { } "mkdir -p $out/lib/fontconfig")
      (pkgs.runCommandLocal "dummy-fc-dir2" { } "mkdir -p $out/lib/fontconfig")
    ];

    home.extraProfileCommands = ''
      if [[ -d $out/lib/X11/fonts || -d $out/share/fonts ]]; then
        export FONTCONFIG_FILE="$(pwd)/fonts.conf"

        cat > $FONTCONFIG_FILE << EOF
      <?xml version='1.0'?>
      <!DOCTYPE fontconfig SYSTEM 'fonts.dtd'>
      <fontconfig>
        <dir>$out/lib/X11/fonts</dir>
        <dir>$out/share/fonts</dir>
        <cachedir>$out/lib/fontconfig/cache</cachedir>
      </fontconfig>
      EOF

        ${lib.getBin pkgs.fontconfig}/bin/fc-cache -f
        rm -f $out/lib/fontconfig/cache/CACHEDIR.TAG
        rmdir --ignore-fail-on-non-empty -p $out/lib/fontconfig/cache

        rm "$FONTCONFIG_FILE"
        unset FONTCONFIG_FILE
      fi

      # Remove the fontconfig directory if no files were available.
      if [[ -d $out/lib/fontconfig ]] ; then
        rmdir --ignore-fail-on-non-empty -p $out/lib/fontconfig
      fi
    '';

    fonts.fontconfig.configFile =
      let
        mkFontconfigConf = conf: ''
          <?xml version='1.0'?>

          <!-- Generated by Home Manager. -->

          <!DOCTYPE fontconfig SYSTEM 'urn:fontconfig:fonts.dtd'>
          <fontconfig>
          ${conf}
          </fontconfig>
        '';
      in
      {
        fonts = {
          enable = true;
          priority = 10;
          text = mkFontconfigConf ''
            <description>Add fonts in the Nix user profile</description>

            <include ignore_missing="yes">${config.home.path}/etc/fonts/conf.d</include>
            <include ignore_missing="yes">${config.home.path}/etc/fonts/fonts.conf</include>

            <dir>${config.home.path}/lib/X11/fonts</dir>
            <dir>${config.home.path}/share/fonts</dir>
            <dir>${config.home.profileDirectory}/lib/X11/fonts</dir>
            <dir>${config.home.profileDirectory}/share/fonts</dir>

            <cachedir>${config.home.path}/lib/fontconfig/cache</cachedir>
          '';
        };
        rendering =
          let
            set =
              name: value:
              let
                xmlValue =
                  if builtins.isBool value then
                    "<bool>${lib.boolToString value}</bool>"
                  else if builtins.isString value then
                    "<const>${value}</const>"
                  else
                    throw "expected bool or string but got ${builtins.typeOf value}: ${toString value}";
              in
              ''
                <match target="font">
                  <edit mode="assign" name="${name}">
                    ${xmlValue}
                  </edit>
                </match>
              '';
            content =
              lib.optional (cfg.antialiasing != null) (set "antialias" cfg.antialiasing)
              ++ lib.optionals (cfg.hinting != null) [
                (set "hinting" true)
                (set "hintstyle" ("hint" + cfg.hinting))
              ]
              ++ lib.optional (cfg.subpixelRendering != null) (
                set "rgba" (builtins.replaceStrings [ "ertical-" ] [ "" ] cfg.subpixelRendering)
              );
          in
          {
            enable = builtins.length content > 0;
            priority = 10;
            text = mkFontconfigConf (
              lib.concatStrings ([ "<description>Set the rendering mode</description>\n" ] ++ content)
            );
          };
        default-fonts =
          let
            genDefault =
              fonts: name:
              lib.optionalString (fonts != [ ]) ''
                <alias binding="same">
                  <family>${name}</family>
                  <prefer>
                  ${lib.concatStringsSep "" (
                    map (font: ''
                      <family>${font}</family>
                    '') fonts
                  )}
                  </prefer>
                </alias>
              '';
          in
          {
            enable = true;
            priority = 52;
            text = mkFontconfigConf ''
              <!-- Default fonts -->
              ${genDefault cfg.defaultFonts.sansSerif "sans-serif"}
              ${genDefault cfg.defaultFonts.serif "serif"}
              ${genDefault cfg.defaultFonts.monospace "monospace"}
              ${genDefault cfg.defaultFonts.emoji "emoji"}
            '';
          };
      };

    xdg.configFile = lib.mapAttrs' (
      _name: config:
      lib.nameValuePair "fontconfig/conf.d/${config.target}" {
        inherit (config) enable source;
      }
    ) cfg.configFile;
  };
}
