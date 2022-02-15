set packpath^=/nix/store/00000000000000000000000000000000-vim-pack-dir
set runtimepath^=/nix/store/00000000000000000000000000000000-vim-pack-dir

" vim-commentary {{{
lua << EOF
-- This should be present in a lua block.
vim.opt.number = true

EOF
" }}}
" This should be present in init.vim
