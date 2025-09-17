{
  programs = {
    bash.enable = true;

    oh-my-posh = {
      enable = true;
      settings = {
        version = 2;
        final_space = true;
        blocks = [
          {
            type = "prompt";
            alignment = "left";
            segments = [
              {
                type = "shell";
                style = "plain";
                template = "{{ .Name }} ";
              }
            ];
          }
        ];
      };
    };
  };

  nmt.script = ''
    assertFileExists home-files/.config/oh-my-posh/config.json
    assertFileContains \
      home-files/.config/oh-my-posh/config.json \
      '"version": 2'
    assertFileContains \
      home-files/.config/oh-my-posh/config.json \
      '"final_space": true'
    assertFileContains \
      home-files/.bashrc \
      '/bin/oh-my-posh init bash --config /home/hm-user/.config/oh-my-posh/config.json'
  '';
}
