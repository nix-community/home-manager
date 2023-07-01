{ config, lib, pkgs, ... }:

let

  cfg = config.programs.timidity;

in {
  meta.maintainers = [ lib.hm.maintainers.amesgen ];

  options.programs.timidity = {
    enable = lib.mkEnableOption "timidity, a software MIDI renderer";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.timidity;
      defaultText = lib.literalExpression "pkgs.timidity";
      description = "The timidity package to use.";
    };

    finalPackage = lib.mkOption {
      readOnly = true;
      type = lib.types.package;
      description = "Resulting package.";
    };

    extraConfig = lib.mkOption {
      type = lib.types.lines;
      default = "";
      example = lib.literalExpression ''
        '''
          soundfont ''${pkgs.soundfont-fluid}/share/soundfonts/FluidR3_GM2-2.sf2
        '''
      '';
      description = "Extra configuration.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.finalPackage ];

    programs.timidity.finalPackage = pkgs.symlinkJoin {
      name = "timidity-with-config";
      paths = [ cfg.package ];
      nativeBuildInputs = [ pkgs.makeWrapper ];
      postBuild = ''
        wrapProgram $out/bin/timidity \
          --add-flags '-c ${pkgs.writeText "timidity.cfg" cfg.extraConfig}'
      '';
    };
  };
}
