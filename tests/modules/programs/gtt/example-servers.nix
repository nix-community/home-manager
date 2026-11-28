{
  programs.gtt = {
    enable = true;

    servers = {
      api_key = {
        deepl = {
          value = "DEEPL_API_KEY";
        };
        deeplx = {
          value = "DEEPLX_API_KEY";
        };
        libre = {
          value = "LIBRE_API_KEY";
        };
      };
      host = {
        deeplx = "127.0.0.1:1188";
        libre = "127.0.0.1:5000";
      };
    };
  };

  test.stubs.gtt.name = "gtt";

  nmt.script =
    let
      configFile = "home-files/.config/gtt/server.yaml";
    in
    ''
      assertFileExists "${configFile}"
      assertFileContent "${configFile}" ${./expected-servers.yaml}
    '';
}
