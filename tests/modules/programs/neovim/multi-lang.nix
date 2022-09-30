{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    programs.neovim = {
      enable = true;
      configLanguages = lib.mkOptionDefault {
        fennel = {
          extension = "fnl";
          luaPackages = with pkgs.lua51Packages; [ fennel ];
          vimPlugins = with pkgs.vimPlugins; [ nvim-moonwalk ];
          enableScript = ''
            require("moonwalk").add_loader("fnl", function(src, path)
                return require("fennel").compileString(src, { filename = path })
            end)
          '';
        };
        teal = {
          extension = "tl";
          luaPackages = with pkgs.lua51Packages; [ tl ];
          vimPlugins = with pkgs.vimPlugins; [ nvim-moonwalk ];
          enableScript = ''
            require("moonwalk").add_loader("tl", function(src, path)
                local tl = require("tl")
                local errs = {}
                local _, program = tl.parse_program(tl.lex(src), errs)
                if #errs > 0 then
                    error(path .. ":" .. errs[1].y .. ":" .. errs[1].x .. ": " .. errs[1].msg, 0)
                end
                return tl.pretty_print_ast(program)
            end)
          '';
        };
      };
      extraConfig = {
        viml = ''
          echo 'Hello from vimscript'
        '';
        lua = ''
          print("Hello from lua\n")
        '';
        fennel = ''
          (print "Hello from fennel\n")
        '';
        teal = ''
          print("Hello from teal\n")
        '';
      };
    };

    nmt.script = let
      nvim = "${config.programs.neovim.finalPackage}/bin/nvim";
      dos2unix = "${pkgs.dos2unix}/bin/dos2unix";
    in ''
      cp $TESTED/home-files/.config . -r --no-preserve=mode

      export HOME=/build
      ${nvim} -c ':q' --headless 2>&1 | ${dos2unix} > nvim_output
      output="$(normalizeStorePaths /build/nvim_output)"

      assertFileRegex "$output" "Hello from vimscript"
      assertFileRegex "$output" "Hello from lua"
      assertFileRegex "$output" "Hello from fennel"
      assertFileRegex "$output" "Hello from teal"
    '';
  };
}

