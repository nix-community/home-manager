{
  services.open-webui = {
    enable = true;
    webuiUrl = "https://chat.example.test";
    openai.baseUrls = [ "http://localhost:8080/v1" ];
    environment.WEBUI_URL = "https://override.example.test";
  };

  nmt.script = ''
    serviceFile=LaunchAgents/org.nix-community.home.open-webui.plist
    assertFileExists "$serviceFile"
    assertFileExists "home-files/.local/share/open-webui/home/.keep"
    assertFileRegex "$serviceFile" 'open-webui serve --host 127\.0\.0\.1 --port 3000'
    assertFileRegex "$serviceFile" '<key>DATA_DIR</key>'
    assertFileRegex "$serviceFile" '<string>[^<]*open-webui/data</string>'
    assertFileRegex "$serviceFile" '<string>[^<]*open-webui/home</string>'
    assertFileRegex "$serviceFile" '<key>OPENAI_API_BASE_URLS</key>'
    assertFileRegex "$serviceFile" '<string>http://localhost:8080/v1</string>'
    assertFileRegex "$serviceFile" '<key>WEBUI_URL</key>'
    assertFileRegex "$serviceFile" '<string>https://override.example.test</string>'
  '';
}
