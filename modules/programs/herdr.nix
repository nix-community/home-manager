{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib) mkIf mkOption;

  cfg = config.programs.herdr;

  tomlFormat = pkgs.formats.toml { };

  binPath = if cfg.package == null then "herdr" else "${lib.getExe cfg.package}";

  # Plugin manifests this module wants to have registered. herdr resolves a
  # linked path to its canonical form, so the desired set is keyed on the
  # canonical store path of each configured package.
  desiredPluginManifests = lib.toJSON (
    lib.mapAttrsToList (_id: plugin: "${toString plugin.package}/herdr-plugin.toml") cfg.plugins
  );

  # Plugin ids registered from the nix store that are no longer configured.
  stalePluginIds = ''
    .result.plugins[]?
    | select((.manifest_path // "") | startswith($store))
    | select((.manifest_path as $p | $desired | index($p)) | not)
    | .plugin_id
  '';

  # Configured plugin manifests that are not registered yet.
  missingPluginManifests = ''
    ($desired - [.result.plugins[]?.manifest_path?])[]
  '';
in
{
  meta.maintainers = [ lib.maintainers.amadejkastelic ];

  options.programs.herdr = {
    enable = lib.mkEnableOption "Herdr";

    package = lib.mkPackageOption pkgs "herdr" { nullable = true; };

    settings = mkOption {
      inherit (tomlFormat) type;
      default = { };
      example = {
        onboarding = false;
        terminal = {
          default_shell = "nu";
          shell_mode = "auto";
          new_cwd = "follow";
        };
        theme = {
          name = "catppuccin";
          auto_switch = true;
          light_name = "catppuccin-latte";
          dark_name = "catppuccin";
        };
        ui = {
          sidebar_width = 32;
          agent_panel_sort = "priority";
          toast.delivery = "herdr";
          sound.enabled = true;
        };
        keys.prefix = "ctrl+b";
        keys.command = [
          {
            key = "prefix+l";
            type = "plugin_action";
            command = "example.layout.apply";
            description = "apply layout";
          }
        ];
      };
      description = ''
        Configuration written to {file}`$XDG_CONFIG_HOME/herdr/config.toml`.
        See <https://herdr.dev/docs/configuration/> for the full list of options.
      '';
    };

    plugins = mkOption {
      type =
        with lib.types;
        attrsOf (submodule {
          options = {
            package = mkOption {
              type = either package path;
              description = ''
                The plugin package or a path to the plugin directory. Its top
                level must contain a {file}`herdr-plugin.toml` manifest; herdr
                reads the plugin id from that manifest when linking.
              '';
            };
          };
        });
      default = { };
      example = lib.literalExpression ''
        {
          "chmarax.herdr-nvim" = {
            package = let
              src = pkgs.fetchFromGitHub {
                owner = "ChmaraX";
                repo = "herdr-nvim";
                rev = "9ce76bba554ba022ee622bcf7b04793011728aa2";
                hash = "sha256-szXayf81beA0ti9kx0uQja49+G59Og2bYOze8v+pbik=";
              };
            in
              pkgs.rustPlatform.buildRustPackage {
                pname = "herdr-nvim";
                version = "0.1.1";
                inherit src;
                cargoLock.lockFile = "''${src}/Cargo.lock";
                postInstall = '''
                  cp -r $src/lua $out/lua
                  cp $src/herdr-plugin.toml $out/
                  mkdir -p $out/herdr
                  cp $src/herdr/run.sh $out/herdr/
                  chmod +x $out/herdr/run.sh
                ''';
              };
          };
        }
      '';
      description = ''
        Plugins to register with herdr. Each value is a plugin package or a
        path to a plugin directory; its top level must contain a
        {file}`herdr-plugin.toml` manifest, from which herdr reads the plugin
        id.

        Plugins registered outside this option, for example with
        {command}`herdr plugin install`, are left untouched.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = lib.mkIf (cfg.package != null) [ cfg.package ];

    xdg.configFile = mkIf (cfg.settings != { }) {
      "herdr/config.toml" = {
        source = tomlFormat.generate "herdr-config.toml" cfg.settings;
        onChange = "${binPath} server reload-config || true";
      };
    };

    home.activation.herdrPlugins = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      registered="$(${binPath} plugin list --json 2>/dev/null || true)"

      # `plugin list` falls back to the on-disk registry when no server is
      # running, so the diff below still converges. `plugin unlink` needs a
      # reachable server and is therefore deferred (best effort) until the
      # next activation, while `plugin link` persists offline.
      printf '%s' "$registered" \
        | ${lib.getExe pkgs.jq} -r \
          --arg store "/nix/store/" \
          --argjson desired ${lib.escapeShellArg desiredPluginManifests} '${stalePluginIds}' \
        | while read -r id; do
            [ -n "$id" ] && ${binPath} plugin unlink "$id" >/dev/null 2>&1 || true
          done

      printf '%s' "$registered" \
        | ${lib.getExe pkgs.jq} -r --argjson desired ${lib.escapeShellArg desiredPluginManifests} '${missingPluginManifests}' \
        | while read -r manifest; do
            [ -n "$manifest" ] && ${binPath} plugin link "$manifest" >/dev/null 2>&1 || true
          done
    '';
  };
}
