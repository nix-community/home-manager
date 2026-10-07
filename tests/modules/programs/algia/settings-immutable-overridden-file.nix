{
  config,
  lib,
  pkgs,
  ...
}:
let
  configDir = "custom-config";
  relativePath = "${
    if pkgs.stdenv.hostPlatform.isDarwin then ".config" else configDir
  }/algia/config.json";
  fileKey = if pkgs.stdenv.hostPlatform.isDarwin then relativePath else "/${relativePath}";
  file = config.home.file.${fileKey};
  expectedTarget = "relocated/algia.json";
  activation = config.home.activation;
in
{
  xdg.configHome = "${config.home.homeDirectory}/${configDir}";
  home.file.${fileKey} = {
    target = expectedTarget;
    source = lib.mkForce (pkgs.writeText "algia-override.json" ''{"followList":["override-user"]}'');
  };
  programs.algia = {
    enable = true;
    settings = {
      relays = {
        "wss =//relay-jp.nostr.wirednet.jp" = {
          read = true;
          write = true;
          search = false;
        };
      };
      privatekey = "nsecXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX";
    };
  };

  assertions = [
    {
      assertion = !config.programs.algia.mutableSettings;
      message = "Algia settings must default to immutable settings.";
    }
    {
      assertion = !(activation ? algiaMutableSettings);
      message = "Immutable algia settings must not register mutable activation.";
    }
    {
      assertion = activation.algiaImmutableSettings.after == [ "writeBoundary" ];
      message = "Immutable cleanup must run after writeBoundary.";
    }
    {
      assertion = activation.algiaImmutableSettings.before == [ "linkGeneration" ];
      message = "Immutable cleanup must run before linkGeneration.";
    }
    {
      assertion = file.enable;
      message = "The immutable algia settings file must remain enabled.";
    }
    {
      assertion = lib.hasInfix (lib.escapeShellArg expectedTarget) activation.algiaImmutableSettings.data;
      message = "Immutable cleanup must use the configured file target.";
    }
    {
      assertion = lib.hasInfix (lib.escapeShellArg (builtins.unsafeDiscardStringContext (toString file.source))) activation.algiaImmutableSettings.data;
      message = "Immutable cleanup must use the configured file source.";
    }
    {
      assertion = file.target == expectedTarget;
      message = "Immutable algia settings must use the configured file target.";
    }
  ];

  nmt.script = ''
    assertFileContent "home-files/${expectedTarget}" ${./override-expected.json}
  '';
}
