{ config, ... }: {
  nmt.script = ''
    assertFileContent \
      home-files/.config/vivid/filetypes.yml \
      ${./filetypes-expected.yml}
  '';

  programs.vivid = {
    enable = true;
    package = config.lib.test.mkStubPackage { };

    filetypes = {
      "core" = {
        "normal_text" = [ "$no" ];
        "regular_file" = [ "$fi" ];
        "reset_to_normal" = [ "$rs" ];
        "directory" = [ "$di" ];
        "symlink" = [ "$ln" ];
        "multi_hard_link" = [ "$mh" ];
        "fifo" = [ "$pi" ];
        "socket" = [ "$so" ];
        "door" = [ "$do" ];
        "block_device" = [ "$bd" ];
        "character_device" = [ "$cd" ];
        "broken_symlink" = [ "$or" ];
        "missing_symlink_target" = [ "$mi" ];
        "setuid" = [ "$su" ];
        "setgid" = [ "$sg" ];
        "file_with_capability" = [ "$ca" ];
        "sticky_other_writable" = [ "$tw" ];
        "other_writable" = [ "$ow" ];
        "sticky" = [ "$st" ];
        "executable_file" = [ "$ex" ];
      };
      "text" = {
        "special" = [
          "CHANGELOG"
          "CHANGELOG.md"
          "CHANGELOG.txt"
          "CODE_OF_CONDUCT"
          "CODE_OF_CONDUCT.md"
          "CODE_OF_CONDUCT.txt"
          "CONTRIBUTING"
          "CONTRIBUTING.md"
          "CONTRIBUTING.txt"
          "CONTRIBUTORS"
          "CONTRIBUTORS.md"
          "CONTRIBUTORS.txt"
          "FAQ"
          "INSTALL"
          "INSTALL.md"
          "INSTALL.txt"
          "LEGACY"
          "NOTICE"
          "README"
          "README.md"
          "README.txt"
          "VERSION"
        ];
        "todo" = [ "TODO" "TODO.md" "TODO.txt" ];
        "licenses" = [
          "COPYING"
          "COPYRIGHT"
          "LICENCE"
          "LICENSE"
          "LICENSE-APACHE"
          "LICENSE-MIT"
        ];
        "configuration" = {
          "generic" = [
            ".cfg"
            ".conf"
            ".config"
            ".ini"
            ".json"
            ".tml"
            ".toml"
            ".webmanifest"
            ".yaml"
            ".yml"
          ];
          "metadata" = [ ".xmp" ];
          "bibtex" = [ ".bib" ".bst" ];
          "dockerfile" = [ "Dockerfile" ];
          "nix" = [ ".nix" ];
          "qt" = [ ".ui" ];
          "desktop" = [ ".desktop" ];
          "system" = [ "passwd" "shadow" ];
        };
        "other" = [ ".txt" ];
      };
      "markup" = {
        "web" = [ ".htm" ".html" ".shtml" ".xhtml" ];
        "other" = [
          ".1"
          ".aseprite-brushes"
          ".aseprite-keys"
          ".csv"
          ".markdown"
          ".md"
          ".mdown"
          ".info"
          ".org"
          ".rst"
          ".tsv"
          ".typ"
          ".xml"
        ];
      };
      "programming" = {
        "source" = {
          "actionscript" = [ ".as" ];
          "ada" = [ ".adb" ".ads" ];
          "applescript" = [ ".applescript" ];
          "asp" = [ ".asa" ];
          "assembly" = [ ".asm" ];
          "awk" = [ ".awk" ];
          "basic" = [ ".vb" ];
          "cabal" = [ ".cabal" ];
          "clojure" = [ ".clj" ];
          "crystal" = [ ".cr" ];
          "csharp" = [ ".cs" ".csx" ];
          "css" = [ ".css" ];
          "cxx" = [
            ".c"
            ".cpp"
            ".cc"
            ".cp"
            ".cxx"
            ".c++"
            ".h"
            ".hh"
            ".hpp"
            ".hxx"
            ".h++"
            ".ino"
            ".inc"
            ".inl"
            ".ipp"
            ".def"
          ];
          "d" = [ ".d" ".di" ];
          "dart" = [ ".dart" ];
          "diff" = [ ".diff" ".patch" ];
          "elixir" = [ ".ex" ".exs" ];
          "emacs" = [ ".elc" ];
          "elm" = [ ".elm" ];
          "erlang" = [ ".erl" ];
          "fsharp" = [ ".fs" ".fsi" ".fsx" ];
          "gcode" = [ ".gcode" ];
          "go" = [ ".go" ];
          "graphviz" = [ ".dot" ".gv" ];
          "groovy" = [ ".groovy" ".gvy" ".gradle" ];
          "hack" = [ ".hack" ];
          "hare" = [ ".ha" ];
          "haskell" = [ ".hs" ];
          "ipython" = [ ".ipynb" ];
          "java" = [ ".java" ".bsh" ];
          "javascript" = [ ".js" ".jsx" ".htc" ];
          "julia" = [ ".jl" ];
          "kotlin" = [ ".kt" ".kts" ];
          "latex" = [ ".tex" ".ltx" ];
          "less" = [ ".less" ];
          "llvm" = [ ".ll" ".mir" ];
          "lisp" = [ ".lisp" ".el" ];
          "lua" = [ ".lua" ];
          "mathematica" = [ ".nb" ];
          "matlab" = [ ".matlab" ".m" ".mn" ];
          "mojo" = [ ".mojo" ];
          "nim" = [ ".nim" ".nims" ".nimble" ];
          "ocaml" = [ ".ml" ".mli" ];
          "openscad" = [ ".scad" ];
          "pascal" = [ ".pas" ".p" ".dpr" ];
          "perl" = [ ".pl" ".pm" ".pod" ".t" ".cgi" ];
          "php" = [ ".php" ];
          "powershell" = [ ".ps1" ".psm1" ".psd1" ];
          "prql" = [ ".prql" ];
          "puppet" = [ ".pp" ".epp" ];
          "purescript" = [ ".purs" ];
          "python" = [ ".py" ];
          "r" = [ ".r" ];
          "raku" = [ ".raku" ];
          "ruby" = [ ".rb" ];
          "rust" = [ ".rs" ];
          "sass" = [ ".sass" ".scss" ];
          "scala" = [ ".scala" ".sbt" ];
          "shell" =
            [ ".sh" ".bash" ".nu" ".bashrc" ".bash_profile" ".zsh" ".fish" ];
          "sql" = [ ".sql" ];
          "swift" = [ ".swift" ];
          "tablegen" = [ ".td" ];
          "tcl" = [ ".tcl" ];
          "typescript" = [ ".ts" ".tsx" ];
          "v" = [ ".v" ".vsh" ];
          "viml" = [ ".vim" ];
          "zig" = [ ".zig" ];
        };
        "tooling" = {
          "vcs" = {
            "git" = [
              ".gitignore"
              ".gitmodules"
              ".gitattributes"
              ".gitconfig"
              ".mailmap"
            ];
            "hg" = [ ".hgrc" "hgrc" ];
            "other" =
              [ "CODEOWNERS" ".ignore" ".fdignore" ".rgignore" ".tfignore" ];
          };
          "build" = {
            "cmake" = [ ".cmake" "CMakeLists.txt" ".cmake.in" ];
            "make" = [ "Makefile" ".make" ".mk" ];
            "automake" = [ "Makefile.am" ];
            "configure" = [ "configure" "configure.ac" ];
            "scons" = [ "SConscript" "SConstruct" ];
            "pip" = [ "requirements.txt" ];
          };
          "packaging" = {
            "go" = [ "go.mod" ];
            "python" = [ "MANIFEST.in" "setup.py" "pyproject.toml" ];
            "ruby" = [ ".gemspec" ];
            "v" = [ "v.mod" ];
          };
          "code-style" = {
            "python" = [ ".flake8" ];
            "cxx" = [ ".clang-format" ];
          };
          "editors" = {
            "editorconfig" = [ ".editorconfig" ];
            "qt" = [ ".pro" ];
            "kdevelop" = [ ".kdevelop" ];
          };
          "documentation" = { "doxygen" = [ "Doxyfile" ".dox" ]; };
          "continuous-integration" = [
            "appveyor.yml"
            "azure-pipelines.yml"
            ".cirrus.yml"
            ".gitlab-ci.yml"
            ".travis.yml"
          ];
        };
      };
      "media" = {
        "image" = {
          "application" = [ ".aseprite" ".ase" ".ai" ".kra" ".psd" ".xvf" ];
          "bitmap" = [
            ".avif"
            ".bmp"
            ".exr"
            ".gif"
            ".heif"
            ".ico"
            ".jpeg"
            ".jpg"
            ".jxl"
            ".pbm"
            ".pcx"
            ".pgm"
            ".png"
            ".ppm"
            ".qoi"
            ".tga"
            ".tif"
            ".tiff"
            ".webp"
            ".xpm"
          ];
          "raw" = [
            ".3fr"
            ".ari"
            ".arw"
            ".bay"
            ".braw"
            ".cap"
            ".cr2"
            ".cr3"
            ".crw"
            ".data"
            ".dcr"
            ".dcs"
            ".dng"
            ".drf"
            ".eip"
            ".erf"
            ".fff"
            ".gpr"
            ".iiq"
            ".k25"
            ".kdc"
            ".mdc"
            ".mef"
            ".mos"
            ".mrw"
            ".nef"
            ".nrw"
            ".obm"
            ".orf"
            ".pef"
            ".ptx"
            ".pxn"
            ".r3d"
            ".raf"
            ".raw"
            ".rw2"
            ".rwl"
            ".rwz"
            ".sr2"
            ".srf"
            ".srw"
            ".x3f"
          ];
          "vector" = [ ".dxf" ".eps" ".svg" ];
        };
        "audio" = [
          ".aif"
          ".ape"
          ".flac"
          ".m3u"
          ".m4a"
          ".mid"
          ".mp3"
          ".ogg"
          ".opus"
          ".wav"
          ".wma"
          ".wv"
        ];
        "video" = [
          ".avi"
          ".flv"
          ".h264"
          ".m4v"
          ".mkv"
          ".mov"
          ".mp4"
          ".mpeg"
          ".mpg"
          ".ogv"
          ".rm"
          ".swf"
          ".vob"
          ".webm"
          ".wmv"
        ];
        "fonts" = [ ".fnt" ".fon" ".otf" ".ttf" ".woff" ".woff2" ];
        "3d" = {
          "application" = [ ".blend" ".hda" ".hip" ".ma" ".mb" ".otl" ];
          "mesh" = [
            ".3ds"
            ".3mf"
            ".alembic"
            ".amf"
            ".dae"
            ".fbx"
            ".iges"
            ".igs"
            ".mtl"
            ".obj"
            ".step"
            ".stl"
            ".stp"
            ".usd"
            ".usda"
            ".usdc"
            ".usdz"
            ".wrl"
            ".x3d"
          ];
        };
      };
      "office" = {
        "document" =
          [ ".doc" ".docx" ".epub" ".odt" ".pdf" ".ps" ".rtf" ".sxw" ];
        "spreadsheet" = [ ".xls" ".xlsx" ".ods" ".xlr" ];
        "presentation" = [ ".ppt" ".pptx" ".odp" ".sxi" ".kex" ".pps" ];
        "calendar" = [ ".ics" ];
      };
      "archives" = {
        "packages" = [ ".apk" ".deb" ".msi" ".rpm" ".xbps" ];
        "ros" = [ ".bag" ];
        "images" = [ ".bin" ".dmg" ".img" ".iso" ".toast" ".vcd" ];
        "other" = [
          ".7z"
          ".arj"
          ".aseprite-extension"
          ".bz"
          ".bz2"
          ".db"
          ".gz"
          ".jar"
          ".paq8n"
          ".paq8o"
          ".pkg"
          ".rar"
          ".tar"
          ".tbz"
          ".tbz2"
          ".tgz"
          ".xz"
          ".z"
          ".zip"
          ".zpaq"
          ".zst"
        ];
      };
      "executable" = {
        "windows" = [ ".bat" ".com" ".exe" ];
        "library" = [ ".so" ".a" ".dll" ".dylib" ];
        "linux" = [ ".ko" ];
      };
      "unimportant" = {
        "build_artifacts" = {
          "cxx" = [ ".o" ".la" ".lo" ];
          "cmake" = [ "CMakeCache.txt" ];
          "automake" = [ "Makefile.in" ];
          "rust" = [ ".rlib" ".rmeta" ];
          "python" = [ ".pyc" ".pyd" ".pyo" ];
          "haskell" = [ ".dyn_hi" ".dyn_o" ".cache" ".hi" ];
          "java" = [ ".class" ];
          "scons" = [ ".scons_opt" ".sconsign.dblite" ];
          "latex" = [
            ".aux"
            ".bbl"
            ".bcf"
            ".blg"
            ".fdb_latexmk"
            ".fls"
            ".idx"
            ".ilg"
            ".ind"
            ".out"
            ".sty"
            ".synctex.gz"
            ".toc"
          ];
          "llvm" = [ ".bc" ];
        };
        "macos" = [ ".CFUserTextEncoding" ".DS_Store" ".localized" "Icon\\r" ];
        "other" = [
          "~"
          ".bak"
          ".ctags"
          ".git"
          ".lock"
          ".log"
          ".orig"
          ".pid"
          ".swp"
          ".swo"
          ".swn"
          ".timestamp"
          ".tmp"
          "stderr"
          "stdin"
          "stdout"
          "bun.lockb"
          "go.sum"
          "package-lock.json"
        ];
      };
    };
  };
}
