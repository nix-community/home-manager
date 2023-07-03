{ config, lib, pkgs, ... }:

let
  cfg = config.programs.ripgrep-all;
  configPath = if pkgs.stdenv.hostPlatform.isDarwin then
    "Library/Application Support/ripgrep-all/config.jsonc"
  else
    "${config.xdg.configHome}/ripgrep-all/config.jsonc";
  customAdapter = lib.types.submodule {
    # Descriptions are largely copied from https://github.com/phiresky/ripgrep-all/blob/v1.0.0-alpha.5/src/adapters/custom.rs
    options = {
      name = lib.mkOption {
        type = lib.types.str;
        description =
          "The unique identifier and name of this adapter; must only include a-z, 0-9, _";
      };
      version = lib.mkOption {
        type = lib.types.int;
        default = 1;
        description =
          "The version identifier used to key cache entries; change if the configuration or program changes";
      };
      description = lib.mkOption {
        type = lib.types.str;
        description = "A description of this adapter; shown in rga's help";
      };
      extensions = lib.mkOption {
        type = with lib.types; listOf str;
        description = "The file extensions this adapter supports";
        example = [ "pdf" ];
      };
      mimetypes = lib.mkOption {
        type = with lib.types; nullOr (listOf str);
        default = null;
        description =
          "If not null and --rga-accurate is enabled, mime type matching is used instead of file name matching";
        example = [ "application/pdf" ];
      };
      binary = lib.mkOption {
        type = lib.types.path;
        description = "The path of the binary to run";
      };
      args = lib.mkOption {
        type = with lib.types; listOf str;
        default = [ ];
        description =
          "The output path hint; the placeholders are the same as for rga's `args`";
      };
      disabled_by_default = lib.mkOption {
        type = with lib.types; nullOr bool;
        default = null;
        description = "If true, the adapter will be disabled by default";
      };
      match_only_by_mime = lib.mkOption {
        type = with lib.types; nullOr bool;
        default = null;
        description =
          "if --rga-accurate, only match by mime types, ignore extensions completely";
      };
      output_path_hint = lib.mkOption {
        type = with lib.types; nullOr str;
        default = null;
        description =
          "Setting this is useful if the output format is not plain text (.txt) but instead some other format that should be passed to another adapter";
        example = "$${input_virtual_path}.txt.asciipagebreaks";
      };
    };
  };
in {
  meta.maintainers = with lib.maintainers; [ lafrenierejm ];

  options = {
    programs.ripgrep-all = {
      enable = lib.mkEnableOption "ripgrep-all (rga)";

      package = lib.mkPackageOption pkgs "ripgrep-all" { nullable = true; };

      custom_adapters = lib.mkOption {
        type = lib.types.listOf customAdapter;
        default = [ ];
        description = ''
          Custom adapters that invoke external preprocessing scripts.
          See <link xlink:href="https://github.com/phiresky/ripgrep-all/wiki#custom-adapters"/>.
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    home = {
      packages = lib.mkIf (cfg.package != null) [ cfg.package ];

      file."${configPath}" = lib.mkIf (cfg.custom_adapters != [ ]) {
        source = (pkgs.formats.json { }).generate "ripgrep-all" {
          "$schema" = "./config.schema.json";
          custom_adapters =
            map (lib.filterAttrs (n: v: v != null)) cfg.custom_adapters;
        };
      };
    };
  };
}
