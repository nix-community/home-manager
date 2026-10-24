{
  services.open-webui = {
    enable = true;
    webuiUrl = "https://chat.example.test";
    openai.baseUrls = [ "http://localhost:8080/v1" ];
    environment.WEBUI_URL = "https://override.example.test";
  };

  nmt.script = ''
    serviceFile="home-files/.config/systemd/user/open-webui.service"
    assertFileExists "$serviceFile"
    assertFileRegex "$serviceFile" 'ExecStart=.*open-webui.*serve.*--host.*127\.0\.0\.1.*--port.*3000'
    assertFileRegex "$serviceFile" 'Environment=.*DATA_DIR=.*open-webui/data'
    assertFileRegex "$serviceFile" 'Environment=OPENAI_API_BASE_URLS=http://localhost:8080/v1'
    assertFileRegex "$serviceFile" 'Environment=WEBUI_URL=https://override.example.test'
    assertFileRegex "$serviceFile" 'WorkingDirectory=.*open-webui/home'
  '';
}
