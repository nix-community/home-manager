{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkOption
    types
    ;
  cfg = config.programs.atool;
in
{
  meta.maintainers = [ lib.hm.maintainers.oneorseveralcats ];

  options.programs.atool = {
    enable = lib.mkEnableOption "atool a commandline archive manager.";

    package = lib.mkPackageOption pkgs "atool" { nullable = true; };

    finalPackage = mkOption {
      type = types.package;
      readOnly = true;
      description = ''
        Final atool package bundled with extraPackages.
      '';
    };

    settings = mkOption {
      type = with types; attrsOf (either str int);
      default = { };
      example = {
        path_unrar = "unrar-free";
      };
      description = ''
        atool settings to generate {file}`~/.atoolrc`.
      '';
    };

    extraPackages = mkOption {
      type = types.listOf types.package;
      default = [ ];
      example = lib.literalExpression ''
        # all supported archive backends
        with pkgs; [ bzip2 cpio gnutar gzip lhasa lzop p7zip unrar-free unzip xz zip ]
      '';
      description = "Extra packages for atool.";
    };
  };

  config =
    let
      # wrap atool package so that it has access to backend programs without
      # polluting user environment.
      atoolPackage = pkgs.symlinkJoin {
        name = "atool-wrapped";
        paths = [ cfg.package ];
        buildInputs = [ pkgs.makeWrapper ];
        postBuild = ''
          wrapProgram $out/bin/atool \
          --suffix PATH : ${lib.makeBinPath cfg.extraPackages}
        '';
      };
    in
    lib.mkIf cfg.enable {
      programs.atool.finalPackage = atoolPackage;

      home.packages = lib.mkIf (cfg.package != null) [
        cfg.finalPackage
      ];

      # config format is:
      #
      # option value
      home.file.".atoolrc" = lib.mkIf (cfg.settings != { }) {
        source = pkgs.writeText ".atoolrc" (
          lib.generators.toKeyValue {
            mkKeyValue = lib.generators.mkKeyValueDefault { } " ";
          } cfg.settings
        );
      };
    };
}
