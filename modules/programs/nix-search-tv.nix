{
  config,
  lib,
  pkgs,
  ...
}:

let
  jsonFormat = pkgs.formats.json { };
  cfg = config.programs.nix-search-tv;
in
{
  meta.maintainers = with lib.hm.maintainers; [
    poseidon-rises
  ];

  options.programs.nix-search-tv = {
    enable = lib.mkEnableOption "nix-search-tv";
    package = lib.mkPackageOption pkgs "nix-search-tv" { nullable = true; };

    settings = lib.mkOption {
      inherit (jsonFormat) type;
      default = { };
      description = ''
        Configuration written to {file}`$XDG_CONFIG_HOME/nix-search-tv/config.json`.
        See <https://github.com/3timeslazy/nix-search-tv?tab=readme-ov-file#configuration>
        for the full list of options.
      '';
      example = lib.literalExpression ''
        {
          indexes = [ "nixpkgs" "home-manager" "nixos" ];

          experimental = {
            render_docs_indexes = {
              nvf = "https://notashelf.github.io/nvf/options.html";
            };
          };
        }
      '';
    };

    enableTelevisionIntegration = lib.mkOption {
      type = lib.types.bool;
      default = config.programs.television.enable;
      defaultText = lib.literalExpression "config.programs.television.enable";
      description = ''
        Enables integration with television. Creates a channel through
        `programs.television.channels.nix-search-tv`, which are set as defaults
        and can be overridden.
        See [programs.television.channels](#opt-programs.television.channels)
        for more information
      '';
      example = true;
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.package != null || cfg.enableTelevisionIntegration;
        message = "Cannot enable television integration when config.programs.nix-search-tv.package is null.";
      }
    ];

    home.packages = lib.mkIf (cfg.package != null) [ cfg.package ];

    xdg.configFile."nix-search-tv/config.json" = lib.mkIf (cfg.settings != { }) {
      source = jsonFormat.generate "config.json" cfg.settings;
    };

    programs.television.channels.nix-search-tv = lib.mkIf cfg.enableTelevisionIntegration (
      let
        nix-search-tv-path = if cfg.package != null then lib.getExe cfg.package else "nix-search-tv";
        keybinding_modifier = if pkgs.stdenv.isDarwin then "alt" else "ctrl";
        opener = if pkgs.stdenv.isDarwin then "open" else "xdg-open";
      in
      {
        metadata = {
          name = "nix-search-tv";
          description = "Search nix options and packages";
        };

        source.command = "${nix-search-tv-path} print";
        preview.command = ''${nix-search-tv-path} preview "{}"'';

        keybindings = {
          "${keybinding_modifier}-r" = "actions:run";
          "${keybinding_modifier}-i" = "actions:shell";
          "${keybinding_modifier}-s" = "actions:source";
          "${keybinding_modifier}-o" = "actions:homepage";
        };

        actions.run = {
          description = "Run the package";
          command = ''nix run {replace:s/\/ /#/g}'';
          mode = "execute";
        };
        actions.shell = {
          description = "Enter new nix shell with this package";
          command = ''nix shell {replace:s/\/ /#/g}'';
          mode = "execute";
        };
        actions.source = {
          description = "Open link to source code";
          command = "${nix-search-tv-path} source '{}' | xargs ${opener}";
          mode = "execute";
        };
        actions.homepage = {
          description = "Open link to homepage";
          command = "${nix-search-tv-path} homepage '{}' | xargs ${opener}";
          mode = "execute";
        };
      }
    );
  };
}
