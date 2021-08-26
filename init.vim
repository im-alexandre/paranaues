let vim_plug_path = expand('~/.config/nvim/autoload/plug.vim')
let vim_plug_just_installed = 0
if !filereadable(vim_plug_path)
    echo "Installing Vim-plug..."
    echo ""
    silent !mkdir -p ~/.config/nvim/autoload
    silent !curl -fLo ~/.config/nvim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
    let vim_plug_just_installed = 1
endif

" manually load vim-plug the first time
if vim_plug_just_installed
    :execute 'source '.fnameescape(vim_plug_path)
endif

call plug#begin("~/.config/nvim/plugged")
    Plug 'jiangmiao/auto-pairs'
    Plug 'lervag/vimtex'
    Plug 'tpope/vim-fugitive'
    Plug 'ryanoasis/vim-devicons'
    Plug 'mileszs/ack.vim'

    Plug 'iamcco/markdown-preview.nvim', { 'do': 'cd app && ./install.sh'  }
    Plug 'vimwiki/vimwiki'
    Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
    Plug 'junegunn/fzf.vim'

    " Code commenter
    Plug 'scrooloose/nerdcommenter'

    " Better file browser
    Plug 'scrooloose/nerdtree'
    Plug 'mbbill/undotree'
    Plug 'sheerun/vim-polyglot'
    "Plug 'Vimjas/vim-python-pep8-indent'
    Plug 'dense-analysis/ale'
    Plug 'neoclide/coc.nvim', {'branch': 'release'}
    Plug 'vim-utils/vim-man'
    " Class/module browser
    Plug 'majutsushi/tagbar'
    "dockerfile
    Plug 'ekalinin/Dockerfile.vim'
    "Snippets
    Plug 'MarcWeber/vim-addon-mw-utils'
    Plug 'tomtom/tlib_vim'
    Plug 'honza/vim-snippets'
    Plug 'garbas/vim-snipmate'
    " Airline
    Plug 'vim-airline/vim-airline'
    Plug 'vim-airline/vim-airline-themes'

    "colorscheme
    Plug 'gruvbox-community/gruvbox'
call plug#end()

"lets
    let g:python3_host_prog = '~/.anaconda3/bin/python'
    let g:coc_disable_startup_warning = 1
    let g:vimtex_fold_enabled = 1
    let g:tex_flavor = 'latex'
    let g:snipMate = { 'snippet_version' : 1 }
    let mapleader=" "
    let g:user_emmet_leader_key=' '
    let fancy_symbols_enabled=0
    let g:vimwiki_key_mappings =
    \ {
    \   'all_maps': 1,
    \   'global': 1,
    \   'headers': 1,
    \   'text_objs': 1,
    \   'table_format': 1,
    \   'table_mappings': 0,
    \   'lists': 0,
    \   'links': 0,
    \   'html': 1,
    \   'mouse': 0,
    \ }

"mappings
    nnoremap <C-J> <C-W><C-J>
    nnoremap <C-K> <C-W><C-K>
    nnoremap <C-L> <C-W><C-L>
    nnoremap <C-H> <C-W><C-H>
    nnoremap <Leader>v+ :vertical resize +15<CR>
    nnoremap <Leader>v- :vertical resize -15<CR>
    nnoremap <Leader>+ :resize +5<CR>
    nnoremap <Leader>- :resize -5<CR>
    map <silent> <leader>md :MarkdownPreview<CR>
    map <silent> <leader>cp :call Captura()<CR>
    nmap <silent> gd <Plug>(coc-definition)
    nmap <leader>rn <Plug>(coc-rename)
    nnoremap <silent> K :call <SID>show_documentation()<CR>
    nnoremap <F8> :CocCommand python.execInTerminal<CR>
    vnoremap <F9> :CocCommand python.execSelectionInTerminal<CR>
    nnoremap <leader>cx :call CompilaLatex()<CR>

"settings
    set shell=/bin/bash
    set cursorline
    set background=dark
    set modifiable
    set splitbelow splitright
    set hidden
    syntax on
    set nohlsearch
    set scrolloff=8
    set nu
    set incsearch
    set foldmethod=indent
    set foldlevel=99
    set encoding=utf-8
    set nobackup
    set undodir=/home/alexandre/.config/nvim/tmp/undodir
    set undofile
    set signcolumn=yes
    set noswapfile
    set nowrap
    set noerrorbells
    set clipboard=unnamedplus
    set relativenumber
    set tabstop=4
    set softtabstop=4
    set shiftwidth=4
    set expandtab
    set autoindent
    set fileformat=unix
    set cmdheight=2

    set colorcolumn=80
    highlight ColorColumn guibg=lightgrey


" ============================================================================
" Plugins settings and mappings
" Edit them as you wish.
" Tagbar -----------------------------
    " toggle tagbar display
    map <F4> :TagbarToggle<CR>
    " autofocus on tagbar open
    let g:tagbar_autofocus = 1

" NERDTree -----------------------------
    " toggle nerdtree display
    map <F3> :NERDTreeToggle<CR>
    " open nerdtree with the current file selected
    nmap <leader>t :NERDTreeFind<CR>
    " don;t show these file types
    let NERDTreeIgnore = ['\.pyc$', '\.pyo$']
    let NERDTreeShowLineNumbers=1
    autocmd FileType nerdtree setlocal relativenumber

" Enable folder icons
    let g:WebDevIconsUnicodeDecorateFolderNodes = 1
    let g:DevIconsEnableFoldersOpenClose = 1

    " Fix directory colors
    highlight! link NERDTreeFlags NERDTreeDir

    " Remove expandable arrow
    let g:WebDevIconsNerdTreeBeforeGlyphPadding = ""
    let g:WebDevIconsUnicodeDecorateFolderNodes = v:true
    let NERDTreeDirArrowExpandable = "\u00a0"
    let NERDTreeDirArrowCollapsible = "\u00a0"
    let NERDTreeNodeDelimiter = "\x07"

    " Autorefresh on tree focus
    function! NERDTreeRefresh()
        if &filetype == "nerdtree"
            silent exe substitute(mapcheck("R"), "<CR>", "", "")
        endif
    endfunction

    silent! autocmd BufEnter * call NERDTreeRefresh()


" My functions
function! Captura()
    :silent !captura
    :sleep 1
    :pu
endfunction

function! CompilaLatex()
    :silent :w
    :!latexmk -pdf %
endfunction


" Fzf ------------------------------
    " file finder mapping
    nmap <leader>e :Files<CR>

" Ack.vim ------------------------------
    " mappings
    nmap <leader>r :Ack
    nmap <leader>wr :execute ":Ack " . expand('<cword>')<CR>

" Yankring -------------------------------
    let g:yankring_history_dir = '~/.config/nvim/tmp'
    let g:yankring_clipboard_monitor = 0

" Airline ------------------------------
    let g:airline_powerline_fonts = 0
    let g:airline_theme = 'bubblegum'
    let g:airline#extensions#whitespace#enabled = 0

    if !exists('g:airline_symbols')
        let g:airline_symbols = {}
    endif

    " unicode symbols
    let g:airline_left_sep = '»'
    let g:airline_left_sep = '▶'
    let g:airline_right_sep = '«'
    let g:airline_right_sep = '◀'
    let g:airline_symbols.crypt = '🔒'
    let g:airline_symbols.linenr = '☰'
    let g:airline_symbols.linenr = '␊'
    let g:airline_symbols.linenr = '␤'
    let g:airline_symbols.linenr = 'Ξ'
    let g:airline_symbols.maxlinenr = ''
    let g:airline_symbols.maxlinenr = '㏑'
    let g:airline_symbols.branch = '⎇'
    let g:airline_symbols.paste = 'ρ'
    let g:airline_symbols.paste = 'Þ'
    let g:airline_symbols.paste = '∥'
    let g:airline_symbols.spell = 'Ꞩ'
    let g:airline_symbols.notexists = 'Ɇ'
    let g:airline_symbols.whitespace = 'Ξ'


" Fancy Symbols!!
    if fancy_symbols_enabled
        let g:webdevicons_enable = 1
        " custom airline symbols
       if !exists('g:airline_symbols')
        let g:airline_symbols = {}
        endif
        let g:airline_left_sep = ''
        let g:airline_left_alt_sep = ''
        let g:airline_right_sep = ''
        let g:airline_right_alt_sep = ''
        let g:airline_symbols.branch = '⭠'
        let g:airline_symbols.readonly = '⭤'
        let g:airline_symbols.linenr = '⭡'
    else
        let g:webdevicons_enable = 0
    endif

" ALE for fixing
    let g:ale_linters = {
          \   'python': ['flake8',],
          \   'javascript': ['eslint'],
          \}

    let g:ale_fixers = {
          \    'python': ['yapf', 'autopep8', 'isort'],
          \}

    nmap <F7> :ALEFix<CR>
    let g:ale_lint_on_save = 1
    let g:ale_fix_on_save = 1

"colorscheme
    let g:gruvbox_contrast_dark='hard'
    colorscheme gruvbox
    "colorscheme dracula
    highlight Normal ctermbg=none
    highlight NonText ctermbg=none

function! s:show_documentation()
  if (index(['vim','help'], &filetype) >= 0)
    execute 'h '.expand('<cword>')
  else
    call CocAction('doHover')
  endif
endfunction

let g:snips_author="Alexandre Castro"
let g:snips_email="im.alexandre07@gmail.com"
let g:snips_github="https://www.github.com/im-alexandre"

let vim_markdown_preview_github=1
let vim_markdown_preview_use_xdg_open=1
let vim_markdown_preview_toggle=3
let g:fzf_layout = { 'window': { 'width': 0.8, 'height': 0.8 } }
set mouse=a
