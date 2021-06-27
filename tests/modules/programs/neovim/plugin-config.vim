set packpath^=/nix/store/00000000000000000000000000000000-vim-pack-dir
set runtimepath^=/nix/store/00000000000000000000000000000000-vim-pack-dir

" vim-commentary {{{
" This should be present too
autocmd FileType c setlocal commentstring=//\ %s
autocmd FileType c setlocal comments=://

" }}}
" This should be present in vimrc
