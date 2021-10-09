{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.go;

in {
  meta.maintainers = [ maintainers.rvolosatovs ];

  options = {
    programs.go = {
      enable = mkEnableOption "Go";

      package = mkOption {
        type = types.package;
        default = pkgs.go;
        defaultText = literalExpression "pkgs.go";
        description = "The Go package to use.";
      };

      packages = mkOption {
        type = with types; attrsOf path;
        default = { };
        example = literalExpression ''
          {
            "golang.org/x/text" = builtins.fetchGit "https://go.googlesource.com/text";
            "golang.org/x/time" = builtins.fetchGit "https://go.googlesource.com/time";
          }
        '';
        description = "Packages to add to GOPATH.";
      };

      goPath = mkOption {
        type = with types; nullOr str;
        default = null;
        example = "go";
        description = ''
          Primary <envar>GOPATH</envar> relative to
          <envar>HOME</envar>. It will be exported first and therefore
          used by default by the Go tooling.
        '';
      };

      extraGoPaths = mkOption {
        type = types.listOf types.str;
        default = [ ];
        example = [ "extraGoPath1" "extraGoPath2" ];
        description = let goPathOpt = "programs.go.goPath";
        in ''
          Extra <envar>GOPATH</envar>s relative to <envar>HOME</envar> appended
          after
          <varname><link linkend="opt-${goPathOpt}">${goPathOpt}</link></varname>,
          if that option is set.
        '';
      };

      goBin = mkOption {
        type = with types; nullOr str;
        default = null;
        example = ".local/bin.go";
        description = "GOBIN relative to HOME";
      };

      goPrivate = mkOption {
        type = with types; listOf str;
        default = [ ];
        example = [ "*.corp.example.com" "rsc.io/private" ];
        description = ''
          The <envar>GOPRIVATE</envar> environment variable controls
          which modules the go command considers to be private (not
          available publicly) and should therefore not use the proxy
          or checksum database.
        '';
      };
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      home.packages = [ cfg.package ];

      home.file = let
        goPath = if cfg.goPath != null then cfg.goPath else "go";
        mkSrc = n: v: { "${goPath}/src/${n}".source = v; };
      in foldl' (a: b: a // b) { } (mapAttrsToList mkSrc cfg.packages);
    }

    (mkIf (cfg.goPath != null) {
      home.sessionVariables.GOPATH = concatStringsSep ":" (map builtins.toPath
        (map (path: "${config.home.homeDirectory}/${path}")
          ([ cfg.goPath ] ++ cfg.extraGoPaths)));
    })

    (mkIf (cfg.goBin != null) {
      home.sessionVariables.GOBIN =
        builtins.toPath "${config.home.homeDirectory}/${cfg.goBin}";
    })

    (mkIf (cfg.goPrivate != [ ]) {
      home.sessionVariables.GOPRIVATE = concatStringsSep "," cfg.goPrivate;
    })
  ]);
}
