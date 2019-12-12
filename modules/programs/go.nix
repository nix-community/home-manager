{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.go;

in

{
  meta.maintainers = [ maintainers.rvolosatovs ];

  options = {
    programs.go = {
      enable = mkEnableOption "Go";

      package = mkOption {
        type = types.package;
        default = pkgs.go;
        defaultText = literalExample "pkgs.go";
        description = "The Go package to use.";
      };

      packages = mkOption {
        type = with types; attrsOf path;
        default = {};
        example = literalExample ''
          {
            "golang.org/x/text" = builtins.fetchGit "https://go.googlesource.com/text";
            "golang.org/x/time" = builtins.fetchGit "https://go.googlesource.com/time";
          }
        '';
        description = "Packages to add to GOPATH.";
      };

      goPath = mkOption {
        type = with types; either (listOf str) (nullOr str);
        default = null;
        example = "go";
        description = "GOPATH relative to HOME or a list of GOPATHs relative to HOME";
      };

      goBin = mkOption {
        type = with types; nullOr str;
        default = null;
        example = ".local/bin.go";
        description = "GOBIN relative to HOME";
      };
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      home.packages = [ cfg.package ];

      home.file =
        let
          goPath =
            if cfg.goPath == null then
              "go"
            else if isString cfg.goPath then
              cfg.goPath
            else if and (isList cfg.goPath) (length cfg.goPath > 0) then
              head cfg.goPath
            else
              throw "You cannot explicitly set zero GOPATHs and at the same time wish to install something to it";

          mkSrc = n: v: {
            target = "${goPath}/src/${n}";
            source = v;
          };
        in
        mapAttrsToList mkSrc cfg.packages;
    }
    (mkIf (cfg.goPath != null) {
      home.sessionVariables.GOPATH =
        if isString cfg.goPath then
          builtins.toPath "${config.home.homeDirectory}/${cfg.goPath}"
        else
          concatStringsSep ":" (map builtins.toPath (map (path: "${config.home.homeDirectory}/${path}") cfg.goPath));
    })
    (mkIf (cfg.goBin != null) {
      home.sessionVariables.GOBIN = builtins.toPath "${config.home.homeDirectory}/${cfg.goBin}";
    })
  ]);
}
