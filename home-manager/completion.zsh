#compdef home-manager

local state ret=1

_arguments \
  '-A[attribute]:ATTRIBUTE:()' \
  '-I[search path]:PATH:_files -/' \
  '-b[backup files]:EXT:()' \
  '--cores[cores]:NUM:()' \
  '--debug[debug]' \
  '--impure[impure]' \
  '--keep-failed[keep failed]' \
  '--keep-going[keep going]' \
  '--version[version]' \
  '(-h --help)'{--help,-h}'[help]' \
  '(-v --verbose)'{--verbose,-v}'[verbose]' \
  '(-n --dry-run)'{--dry-run,-n}'[dry run]' \
  '(-f --file)'{--file,-f}'[configuration file]:FILE:_files' \
  '(-j --max-jobs)'{--max-jobs,-j}'[max jobs]:NUM:()' \
  '--option[option]:NAME VALUE:()' \
  '--builders[builders]:SPEC:()' \
  '(-L --print-build-logs)'{--print-build-logs,-L}'[print build logs]' \
  '--show-trace[show trace]' \
  '--override-input[override flake input]:NAME VALUE:()' \
  '--update-input[update flake input]:NAME:()' \
  '--experimental-features[set experimental Nix features]:VALUE:()' \
  '--extra-experimental-features:[append to experimental Nix features]:VALUE:()' \
  '1: :->cmds' \
  '*:: :->args' && ret=0

case "$state" in
  cmds)
    _values 'command' \
      'help[help]' \
      'edit[edit]' \
      'option[inspect option]' \
      'build[build]' \
      'init[init]' \
      'switch[switch]' \
      'generations[list generations]' \
      'remove-generations[remove generations]' \
      'expire-generations[expire generations]' \
      'packages[managed packages]' \
      'news[read the news]' \
      'uninstall[uninstall]' && ret=0
    ;;
  args)
    case $line[1] in
      remove-generations)
        _values 'generations' \
          $(home-manager generations | cut -d ' ' -f 5) && ret=0
        ;;
      build|switch)
        _arguments \
          '--cores[cores]:NUM:()' \
          '--debug[debug]' \
          '--impure[impure]' \
          '--keep-failed[keep failed]' \
          '--keep-going[keep going]' \
          '--max-jobs[max jobs]:NUM:()' \
          '--no-out-link[no out link]' \
          '--no-substitute[no substitute]' \
          '--option[option]:NAME VALUE:()' \
          '--show-trace[show trace]' \
          '--substitute[substitute]' \
          '--builders[builders]:SPEC:()' \
          '--refresh[refresh]' \
          '--override-input[override flake input]:NAME VALUE:()' \
          '--update-input[update flake input]:NAME:()' \
          '--experimental-features[set experimental Nix features]:VALUE:()' \
          '--extra-experimental-features:[append to experimental Nix features]:VALUE:()'
        ;;
      init)
        _arguments \
          '--switch[switch]' \
          ':PATH:_files -/'
        ;;
    esac
esac

return ret
