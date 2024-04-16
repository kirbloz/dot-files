
" BASICS -------------------------------------------------------------- {{{

set number
"set relativenumber
"set nocompatible
"set mouse=a
set cursorline

syntax enable
filetype plugin on

colorscheme gruvbox
set background=dark

" }}}

" KEYMAPS -------------------------------------------------------------- {{{

" set timeoutlen=500
" inoremap kj <esc>
" vnoremap kj <esc>
" cnoremap kj <C-C>

" }}}

" VIMSCRIPT -------------------------------------------------------------- {{{

" This will enable code folding.
" Use the marker method of folding.
augroup filetype_vim
    autocmd!
    autocmd FileType vim setlocal foldmethod=marker
augroup END

" More Vimscripts code goes here.

" }}}

" PLUGINS -------------------------------------------------------------- {{{


call plug#begin('~/.vim/plugged')

	Plug 'preservim/nerdtree'
	Plug 'neoclide/coc.nvim', {'branch': 'release'}
call plug#end()

" }}}

" STATUS LINE ------------------------------------------------------------ {{{

" clear on reload
" set statusline=

" is left side
" set statusline+=\ %F\ %M\ %Y\ %R

" Use a divider to separate the left side from the right side.
" set statusline+=%=

" Status line right side.
" set statusline+=\ ascii:\ %b\ hex:\ 0x%B\ row:\ %l\ col:\ %c\ percent:\ %p%%

" Show the status on the second to last line.
" set laststatus=2

" status bar colors
au InsertEnter * hi statusline guifg=black guibg=#d7afff ctermfg=black ctermbg=magenta
au InsertLeave * hi statusline guifg=black guibg=#8fbfdc ctermfg=black ctermbg=cyan
hi statusline gui=bold guifg=black guibg=#8fbfdc cterm=bold ctermfg=black ctermbg=cyan

" Status line
" default: set statusline=%f\ %h%w%m%r\ %=%(%l,%c%V\ %=\ %P%)

autocmd cursorhold,bufwritepost * unlet! b:statusline_trailing_space_warning

function! StatuslineTrailingSpaceWarning()
    if !exists("b:statusline_trailing_space_warning")
        if search('\s\+$', 'nw') != 0
            let b:statusline_trailing_space_warning = '[\s]'
        else
            let b:statusline_trailing_space_warning = ''
        endif
    endif
    return b:statusline_trailing_space_warning
endfunction

" Status Line Custom
let g:currentmode={
    \ 'n'  : 'Normal',
    \ 'no' : 'Normal·Operator Pending',
    \ 'v'  : 'Visual',
    \ 'V'  : 'V·Line',
    \ "\<c-V>" : 'V·Block',
    \ 's'  : 'Select',
    \ 'S'  : 'S·Line',
    \ "<c-S>" : 'S·Block',
    \ 'i'  : 'Insert',
    \ 'R'  : 'Replace',
    \ 'Rv' : 'V·Replace',
    \ 'c'  : 'Command',
    \ 'cv' : 'Vim Ex',
    \ 'ce' : 'Ex',
    \ 'r'  : 'Prompt',
    \ 'rm' : 'More',
    \ 'r?' : 'Confirm',
    \ '!'  : 'Shell',
    \ 't'  : 'Terminal'
    \}

set laststatus=2
set noshowmode
set statusline=
set statusline+=%0*\ %{toupper(g:currentmode[mode()])}\     " The current mode
set statusline+=%1*\ %<%F\                                  " File path
set statusline+=%3*│                                        " Separator
set statusline+=%4*%M%r%{StatuslineTrailingSpaceWarning()}  " modified, readonly, trailing space
set statusline+=%2*%h%w                                     " Helpfile, preview
set statusline+=%=                                          " Right Side
set statusline+=%2*\ %Y                                     " FileType
set statusline+=%3*│                                        " Separator
set statusline+=%1*\ %{''.(&fenc!=''?&fenc:&enc).''}        " Encoding
set statusline+=\ [%{&ff}]\                                 " FileFormat
set statusline+=%0*\ ≡\ %02l/%L\ :\ %02v\ [%3p%%]           " See next line
" Line number / total lines, col number, percentage of document

hi User1 ctermfg=007 ctermbg=239 guibg=#4e4e4e guifg=#adadad
hi User2 ctermfg=cyan ctermbg=236 guibg=#303030 guifg=#8fbfdc
hi User3 ctermfg=236 ctermbg=236 guibg=#303030 guifg=#303030
hi User4 ctermfg=001 ctermbg=236 guibg=#303030 guifg=#d75f5f

" }}}
