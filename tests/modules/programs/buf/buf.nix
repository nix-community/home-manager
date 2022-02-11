{ config, lib, pkgs, ... }:

{
  config = {
    programs.buf = { enable = true; };

    nmt.script = ''
      assertFileIsExecutable home-path/bin/buf
      assertFileIsExecutable home-path/bin/protoc-gen-buf-breaking
      assertFileIsExecutable home-path/bin/protoc-gen-buf-lint
    '';
  };
}
