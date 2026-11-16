{
  programs.zk = {
    enable = true;
    settings.notebook.dir = "/home/hm-user/notebook";
    exportNotebookDir = true;
  };

  test.stubs.zk = { };

  nmt.script = ''
    assertFileExists home-files/.config/zk/config.toml
    assertFileContains \
      home-files/.config/zk/config.toml \
      'dir = "/home/hm-user/notebook"'

    assertFileExists home-path/etc/profile.d/hm-session-vars.sh
    assertFileContains \
      home-path/etc/profile.d/hm-session-vars.sh \
      'export ZK_NOTEBOOK_DIR="/home/hm-user/notebook"'
  '';
}
