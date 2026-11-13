{
  config,
  lib,
  pkgs,
  ...
}:
let
  configDir = ".config";
  relativePath = ".config/algia/config.json";
  fileKey = if pkgs.stdenv.hostPlatform.isDarwin then relativePath else "/${relativePath}";
  file = config.home.file.${fileKey};
  activation = config.home.activation;
in
{
  xdg.configHome = "${config.home.homeDirectory}/${configDir}";
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
      assertion = lib.hasInfix (lib.escapeShellArg fileKey) activation.algiaImmutableSettings.data;
      message = "Immutable cleanup must use the configured file target.";
    }
    {
      assertion = lib.hasInfix (lib.escapeShellArg (builtins.unsafeDiscardStringContext (toString file.source))) activation.algiaImmutableSettings.data;
      message = "Immutable cleanup must use the configured file source.";
    }
    {
      assertion = file.target == fileKey;
      message = "Immutable algia settings must use the configured file target.";
    }
  ];

  nmt.script = ''
    assertFileContent "home-files/${fileKey}" ${./config.json}
  '';
}
