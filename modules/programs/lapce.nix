{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.lapce;

  options = {
    enable = mkEnableOption "lapce";
    package = mkPackageOption pkgs "lapce" { };
    channel = mkOption {
      type = types.enum [ "stable" "nightly" ];
      default = "stable";
      description = ''
        Lapce channel to configure.
        Should correspond to the package channel.
        This is used to determine the correct configuration and data directories.
      '';
    };
    settings = mkOption {
      type = settingsFormat.type;
      default = { };
      description = ''
        Configuration written to {file}`$XDG_CONFIG_HOME/lapce/settings.toml`.
        See <https://github.com/lapce/lapce/blob/master/extra/schemas/settings.json> for schema.
      '';
      example = literalExpression ''
        {
          core = {
            custom-titlebar = false;
            color-theme = "Custom";
            icon-theme = "Material Icons";
          };
          editor = {
            font-family = "FiraCode Nerd Bold Font, monospace";
            font-size = 22;
            tab-width = 2;
            cursor-surrounding-lines = 4;
            render-whitespace = "all";
            bracket-pair-colorization = true;
            highlight-matching-brackets = true;
          };
          ui = {
            font-size = 20;
            open-editors-visible = false;
          };
          lapce-nix.lsp-path = "$\{pkgs.nil\}/bin/nil";
        }
      '';
    };
    plugins = mkOption {
      type = types.listOf (types.submodule {
        options = {
          author = mkOption {
            type = types.str;
            description = ''
              Author of the plugin.
            '';
          };
          name = mkOption {
            type = types.str;
            description = ''
              Name of the plugin.
            '';
          };
          version = mkOption {
            type = types.str;
            description = ''
              Version of the plugin.
            '';
          };
          hash = mkOption {
            type = types.str;
            description = ''
              Hash of the plugin tarball.
              To find the hash leave this empty, rebuild and copy the hash from the error message.
            '';
            default = "";
          };
        };
      });
      default = [ ];
      description = ''
        Plugins to install.
      '';
      example = literalExpression ''
        [
          {
            author = "MrFoxPro";
            name = "lapce-nix";
            version = "0.0.1";
            hash = "sha256-...";
          }
          {
            author = "dzhou121";
            name = "lapce-rust";
            version = "0.3.1932";
            hash = "sha256-...";
          }
        ]
      '';
    };
    keymaps = mkOption {
      type = settingsFormat.type;
      default = [ ];
      description = ''
        Keymaps written to {file}`$XDG_CONFIG_HOME/lapce/keymaps.toml`.
        See <https://github.com/lapce/lapce/blob/master/defaults/keymaps-common.toml> for examples.
      '';
      example = literalExpression ''
        [
          {
            command = "open_log_file";
            key = "Ctrl+Shift+L";
          }
        ]
      '';
    };
  };

  settingsFormat = pkgs.formats.toml { };

  fetchPluginTarballFromRegistry = { author, name, version, hash }:
    pkgs.stdenvNoCC.mkDerivation (let
      url =
        "https://plugins.lapce.dev/api/v1/plugins/${author}/${name}/${version}/download";
      file = "lapce-plugin-${author}-${name}-${version}.tar.zstd";
    in {
      name = file;
      nativeBuildInputs = [ pkgs.curl pkgs.cacert ];
      dontUnpack = true;
      dontBuild = true;
      installPhase = ''
        runHook preInstall

        url="$(curl ${url})"
        curl -L "$url" -o "$out"

        runHook postInstall
      '';
      outputHashAlgo = "sha256";
      outputHashMode = "flat";
      outputHash = hash;
      inherit meta;
    });
  pluginFromRegistry = { author, name, version, hash }@args:
    pkgs.stdenvNoCC.mkDerivation {
      pname = "lapce-plugin-${author}-${name}";
      inherit version;
      src = fetchPluginTarballFromRegistry args;
      nativeBuildInputs = [ pkgs.zstd ];
      phases = [ "installPhase" ];
      installPhase = ''
        runHook preInstall

        mkdir -p $out
        tar -C $out -xvf $src

        runHook postInstall
      '';
    };
  pluginsFromRegistry = plugins:
    pkgs.linkFarm "lapce-plugins" (builtins.listToAttrs (builtins.map
      ({ author, name, version, ... }@plugin: {
        name = "${author}-${name}-${version}";
        value = pluginFromRegistry plugin;
      }) plugins));
in {
  meta.maintainers = [ hm.maintainers.timon-schelling ];

  options.programs.lapce = options;

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    xdg = let dir = "lapce-${cfg.channel}";
    in {
      configFile = {
        "${dir}/settings.toml".source =
          settingsFormat.generate "settings.toml" cfg.settings;
        "${dir}/keymaps.toml".source =
          settingsFormat.generate "keymaps.toml" { keymaps = cfg.keymaps; };
      };
      dataFile."${dir}/plugins".source = pluginsFromRegistry cfg.plugins;
    };
  };
}
