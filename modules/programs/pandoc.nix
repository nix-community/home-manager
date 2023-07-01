{ config, lib, pkgs, ... }:

let

  cfg = config.programs.pandoc;

  inherit (lib) literalExpression mkEnableOption mkIf mkOption types;

  jsonFormat = pkgs.formats.json { };

  makeTemplateFile = name: file:
    lib.nameValuePair "pandoc/templates/${name}" { source = file; };

  getFileName = file:
    # This is actually safe here, since it is just a file name
    builtins.unsafeDiscardStringContext (baseNameOf file);

  makeCslFile = file:
    lib.nameValuePair "pandoc/csl/${getFileName file}" { source = file; };

in {
  meta.maintainers = [ lib.maintainers.kirelagin ];

  options.programs.pandoc = {
    enable = mkEnableOption "pandoc";

    package = mkOption {
      type = types.package;
      default = pkgs.pandoc;
      defaultText = literalExpression "pkgs.pandoc";
      description = "The pandoc package to use.";
    };

    # We wrap the executable to pass some arguments
    finalPackage = mkOption {
      type = types.package;
      readOnly = true;
      description = "Resulting package.";
    };

    defaults = mkOption {
      type = jsonFormat.type;
      default = { };
      example = literalExpression ''
        {
          metadata = {
            author = "John Doe";
          };
          pdf-engine = "xelatex";
          citeproc = true;
        }
      '';
      description = ''
        Options to set by default.
        These will be converted to JSON and written to a defaults
        file (see Default files in pandoc documentation).
      '';
    };

    defaultsFile = mkOption {
      type = types.path;
      readOnly = true;
      description = "Resulting defaults file.";
    };

    templates = mkOption {
      type = types.attrsOf types.path;
      default = { };
      example = literalExpression ''
        {
          "default.latex" = path/to/your/template;
        }
      '';
      description = "Custom templates.";
    };

    citationStyles = mkOption {
      type = types.listOf types.path;
      default = [ ];
      example = literalExpression "[ path/to/file.csl ]";
      description = "List of .csl files to install.";
    };
  };

  config = mkIf cfg.enable {
    programs.pandoc = {
      defaultsFile = jsonFormat.generate "hm.json" cfg.defaults;

      finalPackage = pkgs.symlinkJoin {
        name = "pandoc-with-defaults";
        paths = [ cfg.package ];
        nativeBuildInputs = [ pkgs.makeWrapper ];
        postBuild = ''
          wrapProgram "$out/bin/pandoc" \
            --add-flags '--defaults "${cfg.defaultsFile}"'
        '';
      };
    };

    home.packages = [ cfg.finalPackage ];
    xdg.dataFile = lib.mapAttrs' makeTemplateFile cfg.templates
      // lib.listToAttrs (map makeCslFile cfg.citationStyles);
  };
}
