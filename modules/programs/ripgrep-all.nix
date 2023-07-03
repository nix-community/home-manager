{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.ripgrep-all;
  configPath = if pkgs.stdenv.hostPlatform.isDarwin then
    "Library/Application Support/ripgrep-all/config.jsonc"
  else
    "${config.xdg.configHome}/ripgrep-all/config.jsonc";
  customAdapter = types.submodule {
    # Descriptions are largely copied from https://github.com/phiresky/ripgrep-all/blob/v1.0.0-alpha.5/src/adapters/custom.rs
    options = {
      name = mkOption {
        type = types.str;
        description =
          "The unique identifier and name of this adapter; must only include a-z, 0-9, _";
      };
      version = mkOption {
        type = types.int;
        default = 1;
        description =
          "The version identifier used to key cache entries; change if the configuration or program changes";
      };
      description = mkOption {
        type = types.str;
        description = "A description of this adapter; shown in rga's help";
      };
      extensions = mkOption {
        type = types.listOf types.str;
        description = "The file extensions this adapter supports";
        example = [ "pdf" ];
      };
      mimetypes = mkOption {
        type = types.nullOr (types.listOf types.str);
        default = null;
        description =
          "If not null and --rga-accurate is enabled, mime type matching is used instead of file name matching";
        example = [ "application/pdf" ];
      };
      binary = mkOption {
        type = types.path;
        description = "The path of the binary to run";
      };
      args = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description =
          "The output path hint; the placeholders are the same as for rga's `args`";
      };
      disabledByDefault = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = "If true, the adapter will be disabled by default";
      };
      matchOnlyByMime = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description =
          "if --rga-accurate, only match by mime types, ignore extensions completely";
      };
      outputPathHint = mkOption {
        type = types.nullOr types.str;
        default = null;
        description =
          "Setting this is useful if the output format is not plain text (.txt) but instead some other format that should be passed to another adapter";
        example = "$${input_virtual_path}.txt.asciipagebreaks";
      };
    };
  };
  formatCustomAdapter = customAdapter:
    filterAttrs (n: v: v != null) {
      inherit (customAdapter)
        args binary description extensions mimetypes name version;
      match_only_by_mime = customAdapter.matchOnlyByMime;
      disabled_by_default = customAdapter.disabledByDefault;
      output_path_hint = customAdapter.outputPathHint;
    };
in {
  meta.maintainers = [ maintainers.lafrenierejm ];

  options = {
    programs.ripgrep-all = {
      enable = mkEnableOption "ripgrep-all (rga)";

      package = mkPackageOption pkgs "ripgrep-all" { };

      customAdapters = mkOption {
        type = types.listOf customAdapter;
        default = [ ];
        description = ''
          Custom adapters that invoke external preprocessing scripts.
          See <link xlink:href="https://github.com/phiresky/ripgrep-all/wiki#custom-adapters"/>.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    home = {
      packages = [ cfg.package ];

      file."${configPath}" = mkIf (cfg.customAdapters != [ ]) {
        source = (pkgs.formats.json { }).generate "ripgrep-all" {
          "$schema" = "./config.schema.json";
          custom_adapters = map formatCustomAdapter cfg.customAdapters;
        };
      };
    };
  };
}
