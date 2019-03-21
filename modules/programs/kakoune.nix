{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.kakoune;
  highlighterModule = types.submodule {
    options = {
       name = mkOption {
         type = types.string;
         default = "";
         description = ''
           The name of the highlighter.
           If empty, it will be set automatically.
         '';
       };

       group = mkOption {
         type = types.listOf types.string;
         default = [];
         description = ''
           The group the highlighter belongs to.
         '';
       };
 
       command = mkOption {
         type = types.string;
         description = ''
           What the highlighter does.
         '';
       };

       arguments = mkOption {
         type = types.listOf types.string;
         default = [];
         description = ''
           Extra arguments for the highlighter.
         '';
       };
    };
  };

  configModule = types.submodule {
    options = {
      globalHighlighters = mkOption {
         type = types.listOf highlighterModule;
         default = [];
         description = ''
           Highlighters that should be globally enabled.
         '';
      };
    };
  };

  highlighterStr = highlighters: concatStringsSep "\n" (
    map (hl: let nameString = concatStringsSep "/" (["global"] ++ hl.group ++ [hl.name]);
                 argsString = concatStringsSep " " (map (a: "-" + a) hl.arguments);
             in "add-highlighter ${nameString} ${hl.command} ${argsString} ") highlighters
  );

  configFile = pkgs.writeText "kakrc" ((if cfg.config != null then ''
    ${highlighterStr cfg.config.globalHighlighters}
  '' else "") + "\n" + cfg.extraConfig);

in
{
  options = {
    programs.kakoune = {
      enable = mkEnableOption "kakoune text editor.";
 
      config = mkOption {
        type = types.nullOr configModule;
        default = {};
        description = "kakoune configuration options.";
      };

      extraConfig = mkOption {
        type = types.lines;
        default = "";
        description = "Extra configuration lines to add to ~/.config/kak/kakrc.";
      };
    };
  };

  config = mkIf cfg.enable(mkMerge [
    {
      home.packages = [ pkgs.kakoune ];
      xdg.configFile."kak/kakrc-test".source = configFile;
    }
  ]);
}
