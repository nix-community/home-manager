{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    literalExpression
    mkIf
    mkMerge
    mkOption
    optional
    types
    ;

  cfg = config.programs.sequoia-pgp;
  tomlFormat = pkgs.formats.toml { };

  generatedConfig = tomlFormat.generate "sequoia-pgp-config.toml" cfg.settings;

  configSource = pkgs.concatText "sequoia-pgp-config.toml" (
    [ generatedConfig ]
    ++ optional (cfg.extraConfig != "") (
      pkgs.writeText "sequoia-pgp-extra-config.toml" "\n${cfg.extraConfig}\n"
    )
  );
in
{
  meta.maintainers = [ lib.maintainers.philocalyst ];

  options.programs.sequoia-pgp = {
    enable = lib.mkEnableOption "Sequoia PGP";

    package = lib.mkPackageOption pkgs "sequoia-sq" { nullable = true; };

    settings = mkOption {
      type = tomlFormat.type;
      default = { };
      example = literalExpression ''
        {
          ui.verbosity = "quiet";
          network.keyservers = [ "hkps://keys.openpgp.org" ];
        }
      '';
      description = ''
        Freeform Sequoia `sq` configuration written to
        {file}`config.toml`.
      '';
    };

    extraConfig = mkOption {
      type = types.lines;
      default = "";
      example = ''
        [policy.hash_algorithms]
        sha1 = 2010-01-01
      '';
      description = ''
        Raw TOML appended to the generated Sequoia `sq` configuration file.
        Useful for values such as TOML dates that cannot be represented by
        the Nix TOML generator.
      '';
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      home.packages = lib.mkIf (cfg.package != null) [ cfg.package ];
    }

    (mkIf pkgs.stdenv.hostPlatform.isDarwin {
      home.file."Library/Application Support/org.Sequoia-PGP.sequoia/sq/config.toml".source =
        configSource;
    })

    (mkIf pkgs.stdenv.hostPlatform.isLinux {
      xdg.configFile."sequoia/sq/config.toml".source = configSource;
    })
  ]);
}
