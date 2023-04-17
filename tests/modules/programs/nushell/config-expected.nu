let-env config = {
  completions: {
    external: {
      completer: {|spans|
        carapace $spans.0 nushell $spans | from json
      }
      
      enable: true
      max_results: 100
    }
  }
  filesize: {
    metric: false
  }
  ls: {
    colors: true
  }
  table: {
    mode: "rounded"
  }
}

source $HOME/file_a.nu

source $HOME/file_b.nu
