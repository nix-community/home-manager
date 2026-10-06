{
  config,
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
  activation = config.home.activation;
in
{
  xdg.configHome = "${config.home.homeDirectory}/${configDir}";
  home.file.${fileKey}.enable = false;
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
      assertion = !file.enable;
      message = "The disabled algia settings file must remain disabled.";
    }
    {
      assertion = activation.algiaImmutableSettings.data == "";
      message = "Disabled algia settings files must not create cleanup commands.";
    }
    {
      assertion = file.target == fileKey;
      message = "Immutable algia settings must use the configured file target.";
    }
  ];

  nmt.script = ''
    assertPathNotExists "home-files/${relativePath}"
  '';
}
