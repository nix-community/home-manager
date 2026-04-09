{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.kanata;

  allKeyboards = cfg.keyboards // lib.optionalAttrs (cfg.default != null) { default = cfg.default; };

  effectiveConfigFile =
    name: kbd:
    if kbd.configFile != null then
      toString kbd.configFile
    else
      "${config.xdg.configHome}/kanata/${name}.kbd";

  mkProgramArguments =
    name: kbd:
    [
      (lib.getExe cfg.package)
      "--cfg"
      (effectiveConfigFile name kbd)
      "--nodelay"
      "--no-wait"
    ]
    ++ lib.optionals (kbd.port != null) [
      "--port"
      (toString kbd.port)
    ]
    ++ kbd.extraArgs;
in
{
  config = lib.mkIf (cfg.enable && pkgs.stdenv.isDarwin) {

    launchd.agents = lib.mapAttrs' (
      name: kbd:
      lib.nameValuePair "kanata-${name}" {
        enable = true;
        config = {
          ProgramArguments = mkProgramArguments name kbd;
          KeepAlive = {
            Crashed = true;
            SuccessfulExit = false;
          };
          RunAtLoad = true;
          ProcessType = "Interactive";
        };
      }
    ) allKeyboards;

  };
}
