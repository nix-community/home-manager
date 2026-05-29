{ pkgs, lib, ... }:
let
  fakeSecret = pkgs.writeText "fake-npm-token" "supersecret";

  wrapper = lib.hm.mcp.mkEnvFilesWrapper {
    inherit pkgs;
    name = "test-server";
    server = {
      command = "npx";
      args = [
        "-y"
        "@modelcontextprotocol/server-everything"
      ];
      env.NPM_TOKEN.file = "${fakeSecret}";
    };
  };

  wrapperNoArgs = lib.hm.mcp.mkEnvFilesWrapper {
    inherit pkgs;
    name = "test-server-noargs";
    server = {
      command = "npx";
      env.NPM_TOKEN.file = "${fakeSecret}";
    };
  };
in
{
  home.file."mcp-wrapper-under-test" = {
    source = wrapper;
  };
  home.file."mcp-wrapper-noargs-under-test" = {
    source = wrapperNoArgs;
  };

  nmt.script = ''
    assertFileContains home-files/mcp-wrapper-under-test \
      'if NPM_TOKEN=$(cat ${fakeSecret}); then'
    assertFileContains home-files/mcp-wrapper-under-test \
      'export NPM_TOKEN'
    assertFileContains home-files/mcp-wrapper-under-test \
      'exec npx -y @modelcontextprotocol/server-everything'
    assertFileContains home-files/mcp-wrapper-noargs-under-test \
      'exec npx'
  '';
}
