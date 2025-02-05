{
  programs.pet = {
    enable = true;
    snippets = [{
      description = "git: search full history for regex";
      command = "git log -p -G <regex>";
      tag = [ "git" "regex" ];
    }];
  };

  nmt.script = ''
    assertFileContent home-files/.config/pet/snippet.toml ${./snippet.toml}
  '';
}
