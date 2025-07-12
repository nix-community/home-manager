{ config, lib, ... }:
let
  inherit (lib) mkOption types;

  cfg = config.programs.zsh;
in
{
  imports = [
    (lib.mkRenamedOptionModule
      [ "programs" "zsh" "enableAutosuggestions" ]
      [ "programs" "zsh" "autosuggestion" "enable" ]
    )
    (lib.mkRenamedOptionModule
      [ "programs" "zsh" "enableSyntaxHighlighting" ]
      [ "programs" "zsh" "syntaxHighlighting" "enable" ]
    )
  ];

  options = {
    programs.zsh = {
      initExtraBeforeCompInit = mkOption {
        default = "";
        type = types.lines;
        apply =
          x:
          lib.warnIfNot (x == "") ''
            `programs.zsh.initExtraBeforeCompInit` is deprecated, use `programs.zsh.initContent` with `lib.mkOrder 550` instead.

            Example: programs.zsh.initContent = lib.mkOrder 550 "your content here";
          '' x;
        visible = false;
        description = ''
          Extra commands that should be added to {file}`.zshrc` before compinit.
        '';
      };

      initExtra = mkOption {
        default = "";
        type = types.lines;
        visible = false;
        apply =
          x:
          lib.warnIfNot (x == "") ''
            `programs.zsh.initExtra` is deprecated, use `programs.zsh.initContent` instead.

            Example: programs.zsh.initContent = "your content here";
          '' x;
        description = ''
          Extra commands that should be added to {file}`.zshrc`.
        '';
      };

      initExtraFirst = mkOption {
        default = "";
        type = types.lines;
        visible = false;
        apply =
          x:
          lib.warnIfNot (x == "") ''
            `programs.zsh.initExtraFirst` is deprecated, use `programs.zsh.initContent` with `lib.mkBefore` instead.

            Example: programs.zsh.initContent = lib.mkBefore "your content here";
          '' x;
        description = ''
          Commands that should be added to top of {file}`.zshrc`.
        '';
      };
    };
  };

  config = {
    programs.zsh.initContent = lib.mkMerge [
      (lib.mkIf (cfg.initExtraFirst != "") (lib.mkBefore cfg.initExtraFirst))

      (lib.mkIf (cfg.initExtraBeforeCompInit != "") (lib.mkOrder 550 cfg.initExtraBeforeCompInit))

      (lib.mkIf (cfg.initExtra != "") cfg.initExtra)
    ];
  };
}
