" :PlugList       - lists configured plugins
" :PlugInstall    - installs plugins; append `!` to update or just :PluginUpdate
" :PlugSearch foo - searches for foo; append `!` to refresh local cache
" :PlugClean      - confirms removal of unused plugins; append `!` to auto-approve removal

" - Avoid using standard Vim directory names like 'plugin'
call plug#begin('~/.vim/plugged')

" Make sure you use single quotes

" Shorthand notation; fetches https://github.com/junegunn/vim-easy-align
Plug 'scrooloose/nerdtree'
Plug 'tpope/vim-sensible'
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
Plug 'xolox/vim-misc'
Plug 'flazz/vim-colorschemes'
Plug 'tpope/vim-fugitive'
Plug 'Yggdroot/indentLine'
Plug 'ryanoasis/vim-devicons'
Plug 'moll/vim-bbye'

Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
Plug 'junegunn/fzf.vim'

" initialize plugin system
call plug#end()

set encoding=UTF-8

" map leader to the space key
let mapleader = "\<space>"

" store swap files in fixed location, not current directory.
set swapfile
set dir=~/.vim/swap//,/var/tmp//,/tmp//,.

" store temporary files in a fixed location, not current directory
set backup
set backupdir=~/.vim/backup//,/var/tmp//,/tmp//,.

" set tab size
set tabstop=4       " The width of a TAB is set to 4.
                    " Still it is a \t. It is just that
                    " Vim will interpret it to be having
                    " a width of 4.
set shiftwidth=4    " Indents will have a width of 4
set softtabstop=4   " Sets the number of columns for a TAB
set expandtab       " Expand TABs to spaces

autocmd FileType yaml setlocal ts=2 sts=2 sw=2 expandtab

" color scheme
syntax enable
colorscheme badwolf

set relativenumber
set number
set cursorline

set incsearch hlsearch

" Allow changing of buffers even with unsaved changes
set hidden

set confirm

" Toggle paste mode
nnoremap <F2> :set invpaste paste?<CR>
set pastetoggle=<F2>
set showmode

" NerdTree mapping
map <C-n> :NERDTreeToggle<CR>
" Allow NerdTree to start without path
autocmd StdinReadPre * let s:std_in=1
autocmd VimEnter * if argc() == 0 && !exists("s:std_in") | NERDTree | endif
" Exit Vim if NERDTree is the only window remaining in the only tab.
autocmd BufEnter * if tabpagenr('$') == 1 && winnr('$') == 1 && exists('b:NERDTree') && b:NERDTree.isTabTree() | quit | endif
" Close the tab if NERDTree is the only window remaining in it.
autocmd BufEnter * if winnr('$') == 1 && exists('b:NERDTree') && b:NERDTree.isTabTree() | quit | endif

" Use ripgrep over grep
if executable("rg")
  set grepprg=rg\ --vimgrep\ --smart-case\ --hidden
  set grepformat=%f:%l:%c:%m
endif

" bind K to grep word under cursor
nnoremap <leader>k :grep! "\b<C-R><C-W>\b"<CR>:cw<CR>

let g:airline_powerline_fonts = 1
" Automatically displays all buffers when there's only one tab open
let g:airline#extensions#tabline#enabled = 2
" Just show the filename (no path) in the tab
let g:airline#extensions#tabline#fnamemod = ':t'

let g:airline_theme='badwolf'

" Switch between windows, maximizing the current window
map <C-j> <C-W>j
map <C-k> <C-W>k
map <C-h> <C-W>h
map <C-l> <C-W>l

" Buffers - next/previous/delete
map gn :bn<cr>
map gp :bp<cr>
map gd :Bdelete<cr>

" PrettyPrint commands
command! PrettyPrintJSON %!python -m json.tool
command! PrettyPrintHTML !tidy -miq -html -wrap 0 %
command! PrettyPrintXML !tidy -miq -xml -wrap 0 %

" fzf mappings
nmap <Leader>b :Buffers<CR>
nmap <Leader>f :Files<CR>
nmap <Leader>h :History<CR>
nmap <Leader>l :Lines<CR>

" indentLine character
let g:indentLine_char = '⦙'

