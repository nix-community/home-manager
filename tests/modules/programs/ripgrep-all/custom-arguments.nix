{ pkgs, config, ... }: {
  config = {
    programs.ripgrep-all = {
      enable = true;
      package = config.lib.test.mkStubPackage { name = "ripgrep-all"; };
      custom_adapters = [{
        name = "gron";
        version = 1;
        description = "Transform JSON into discrete JS assignments";
        extensions = [ "json" ];
        mimetypes = [ "application/json" ];
        binary = "/bin/gron";
        disabled_by_default = false;
        match_only_by_mime = false;
      }];
    };

    nmt.script = let
      configPath = if pkgs.stdenv.hostPlatform.isDarwin then
        "Library/Application Support/ripgrep-all/config.jsonc"
      else
        ".config/ripgrep-all/config.jsonc";
    in ''
      assertFileExists "home-files/${configPath}"
      assertFileContent "home-files/${configPath}" ${
        pkgs.writeText "ripgrep-all.expected" ''
          {
            "$schema": "./config.schema.json",
            "custom_adapters": [
              {
                "args": [],
                "binary": "/bin/gron",
                "description": "Transform JSON into discrete JS assignments",
                "disabled_by_default": false,
                "extensions": [
                  "json"
                ],
                "match_only_by_mime": false,
                "mimetypes": [
                  "application/json"
                ],
                "name": "gron",
                "version": 1
              }
            ]
          }
        ''
      }
    '';
  };
}
