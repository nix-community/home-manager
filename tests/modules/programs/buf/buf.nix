{ config, lib, pkgs, ... }:

{
  config = {
    programs.buf = { enable = true; };

    nmt.script = ''
      assertFileExists home-path/bin/buf
      assertFileExists home-path/bin/protoc-gen-buf-breaking
      assertFileExists home-path/bin/protoc-gen-buf-lint
    '';
  };
}
