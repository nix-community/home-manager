{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkOption types;

  cfg = config.programs.zsh;
in
{
  imports = [
    (lib.mkRenamedOptionModule [ "programs" "zsh" "zproof" ] [ "programs" "zsh" "zprof" ])
  ];

  options.programs.zsh.zprof = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Enable zprof in your zshrc.
      '';
    };
  };

  config = lib.mkIf cfg.zprof.enable {
    programs.zsh.initContent = lib.mkMerge [
      # zprof must be loaded before everything else, since it
      # benchmarks the shell initialization.
      (lib.mkOrder 400 ''
        zmodload zsh/zprof
      '')

      (lib.mkOrder 1450 "zprof")
    ];
  };
}
