{ config, lib, pkgs, ... }:

with lib;

{
  config = (
    let
      export = n: v: "export ${n}=\"${toString v}\"";
      setenv = n: v: "setenv ${n} \"${toString v}\"";
      shEnvVarsStr = concatStringsSep "\n" (
        mapAttrsToList export config.home.sessionVariables
      );
      cshEnvVarsStr = concatStringsSep "\n" (
        mapAttrsToList setenv config.home.sessionVariables
      );
    in mkIf (config.home.sessionVariableSetter == "shell"
      || config.home.sessionVariableSetter == "bash") {
      home.file.".local/share/home-manager/env.sh".text = ''
        ${shEnvVarsStr}
      '';
      home.file.".local/share/home-manager/env.csh".text = ''
        ${cshEnvVarsStr}
      '';
    }
  );
}
