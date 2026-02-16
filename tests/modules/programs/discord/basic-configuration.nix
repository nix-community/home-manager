{ pkgs, ... }:
{
  config = {
    programs.discord = {
      enable = true;
      settings.DANGEROUS_ENABLE_DEVTOOLS_ONLY_ENABLE_IF_YOU_KNOW_WHAT_YOURE_DOING = true;
    };

    nmt.script =
      let
        configDir =
          if pkgs.stdenv.hostPlatform.isLinux then
            "home-files/.config/discord"
          else
            "home-files/Library/Application Support/discord";
      in
      ''
        assertFileExists "${configDir}/settings.json"
        assertFileContent "${configDir}/settings.json" \
          ${./basic-settings.json}
      '';
  };
}
