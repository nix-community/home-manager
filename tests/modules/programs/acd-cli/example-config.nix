{
  programs.acd-cli = {
    enable = true;
    cliSettings = {
      download = {
        keep_corrupt = false;
        keep_incomplete = true;
      };

      upload = {
        timeout_wait = 10;
      };
    };

    clientSettings = {
      endpoints = {
        filename = "endpoint_data";
        validity_duration = 259200;
      };

      transfer = {
        fs_chunk_size = 131072;
        dl_chunk_size = 524288000;
        chunk_retries = 1;
        connection_timeout = 30;
        idle_timeout = 60;
      };
    };

    cacheSettings = {
      sqlite = {
        filename = "nodes.db";
        busy_timeout = 30000;
        journal_mode = "wal";
      };
    };

    fuseSettings = {
      fs.block_size = 512;
      read.open_chunk_limit = 10;
      write = {
        buffer_size = 32;
        timeout = 30;
      };
    };
  };

  nmt.script = ''
    assertFileExists home-files/.config/acd_cli/acd_cli.ini
    assertFileContent home-files/.config/acd_cli/acd_cli.ini \
      ${./acd_cli.ini}

    assertFileExists home-files/.config/acd_cli/acd_client.ini
    assertFileContent home-files/.config/acd_cli/acd_client.ini \
      ${./acd_client.ini}

    assertFileExists home-files/.config/acd_cli/cache.ini
    assertFileContent home-files/.config/acd_cli/cache.ini \
      ${./cache.ini}

    assertFileExists home-files/.config/acd_cli/fuse.ini
    assertFileContent home-files/.config/acd_cli/fuse.ini \
      ${./fuse.ini}
  '';
}
