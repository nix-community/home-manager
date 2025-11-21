{ config, pkgs, ... }:
{
  config = {
    programs.mods = {
      enable = true;
      package = pkgs.writeScriptBin "dummy-mods" "";
      settings = {
        default-model = "llama3.2";
        apis = {
          ollama = {
            base-url = "http://localhost:11434/api";
            models = {
              "llama3.2" = {
                max-input-chars = 650000;
              };
            };
          };
        };
      };
    };
    nmt.script = ''
      assertFileExists home-files/.config/mods/mods.yml
      assertFileContent home-files/.config/mods/mods.yml \
          ${./basic-configuration.yml}
    '';
  };
}
