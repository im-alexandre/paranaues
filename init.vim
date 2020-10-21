let g:airline#extensions#clock#format = '%H:%M:%S'
let g:airline#extensions#clock#updatetime = 1000
set cursorline
set background=dark
let g:gruvbox_contrast_dark='hard'
set modifiable
let g:python3_host_prog = '/home/alexandre/.anaconda3/bin/python'
let g:coc_disable_startup_warning = 1
let vim_plug_just_installed = 0
let vim_plug_path = expand('~/.config/nvim/autoload/plug.vim')
let g:vimtex_fold_enabled = 1
let g:tex_flavor = 'latex'

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
    Plug 'lervag/vimtex'
    Plug 'enricobacis/vim-airline-clock'
    Plug 'tpope/vim-fugitive'
    Plug 'ryanoasis/vim-devicons'
    Plug 'mileszs/ack.vim'
    " Distraction free writing by removing UI elements and centering everything.
    Plug 'plasticboy/vim-markdown'
    Plug 'iamcco/markdown-preview.nvim', { 'do': 'cd app && ./install.sh'  }    
    Plug 'vimwiki/vimwiki'
    Plug 'goerz/jupytext.vim'
    Plug 'scrooloose/nerdtree'
    Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
    Plug 'junegunn/fzf.vim'

    " Code commenter
    Plug 'scrooloose/nerdcommenter'

    " Better file browser
    Plug 'scrooloose/nerdtree'
    Plug 'jeetsukumaran/vim-pythonsense'
    Plug 'mbbill/undotree'
    Plug 'Townk/vim-autoclose'
    Plug 'sheerun/vim-polyglot'
    Plug 'Vimjas/vim-python-pep8-indent'
    Plug 'dense-analysis/ale'
    Plug 'neoclide/coc.nvim', {'branch': 'release'}
    Plug 'vim-utils/vim-man'
    "Treinamento Vim
    Plug 'ThePrimeagen/vim-be-good', {'do': './install.sh'}
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
    " Just to add the python go-to-definition and similar features, autocompletion
    " from this plugin is disabled
    Plug 'davidhalter/jedi-vim'

    "colorscheme
    Plug 'gruvbox-community/gruvbox'
    "Plug 'dracula/vim', { 'as': 'dracula' }
call plug#end()

"autocmd silent! BufWritePre *.py :%s/\s\+$//e
set shell=/bin/bash 

"mappings
    nnoremap <silent> // :noh<CR>
    nnoremap <space> za
    nnoremap <C-J> <C-W><C-J>
    nnoremap <C-K> <C-W><C-K>
    nnoremap <C-L> <C-W><C-L>
    nnoremap <C-H> <C-W><C-H>
    let mapleader=" "
    nnoremap <Leader>+ :vertical resize +15<CR>
    nnoremap <Leader>- :vertical resize -15<CR>
    map <silent> <leader>md :MarkdownPreview<CR>
    map <silent> <leader>cp :call Captura()<CR>
    nmap <silent> gd <Plug>(coc-definition)
    nmap <leader>rn <Plug>(coc-rename)
    nnoremap <silent> K :call <SID>show_documentation()<CR>
    let g:user_emmet_leader_key=' '
    nnoremap <F8> :CocCommand python.execInTerminal<CR>
    vnoremap <F9> :CocCommand python.execSelectionInTerminal<CR>
    nnoremap <leader>cj :CocCommand java.workspace.compile<CR>
    nnoremap <leader>cx :call CompilaLatex()<CR>

"settings
    set splitbelow splitright
    set hidden
    syntax on
    set nu
    set incsearch
    set smartcase
    set hlsearch
    set foldmethod=indent
    set foldlevel=99
    set encoding=utf-8
    set nobackup
    set undodir=/home/alexandre/.config/nvim/tmp/undodir
    set undofile
    set noswapfile
    set nowrap
    set noerrorbells
    set clipboard=unnamedplus
    set relativenumber
    
    set colorcolumn=80
    highlight ColorColumn ctermbg=0 guibg=lightgrey

"Filetypes
au BufNewFile,BufRead *.js silent!
  set tabstop=2
  set softtabstop=2
  set shiftwidth=2
  
au BufNewFile,BufRead *.html silent!
  set tabstop=2
  set softtabstop=2
  set shiftwidth=2
    
au BufNewFile,BufRead *.css silent!
  set tabstop=2
  set softtabstop=2
  set shiftwidth=2

au BufNewFile,BufRead *.py silent!
  set tabstop=4
  set softtabstop=4
  set shiftwidth=4
  set expandtab
  set autoindent
  set fileformat=unix

au BufNewFile,BufRead *.md silent!
  set tabstop=4
  set softtabstop=4
  set shiftwidth=4
  set expandtab
  set autoindent
  set fileformat=unix

autocmd FileType htmldjango silent! setlocal shiftwidth=2 tabstop=2 softtabstop=2


let fancy_symbols_enabled = 1
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
    nmap ,t :NERDTreeFind<CR>
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

    function! Captura()
        :silent !captura
        :sleep 1
        :pu
    endfunction

    function! CompilaLatex()
        :silent :w
        :!latexmk -pdf %
    endfunction


" Tasklist ------------------------------
    " show pending tasks list
    map <F2> :TaskList<CR>
    
" Fzf ------------------------------
    " file finder mapping
    nmap ,e :Files<CR>
    " tags (symbols) in current file finder mapping
    nmap ,g :BTag<CR>
    " the same, but with the word under the cursor pre filled
    nmap ,wg :execute ":BTag " . expand('<cword>')<CR>
    " tags (symbols) in all files finder mapping
    nmap ,G :Tags<CR>
    " the same, but with the word under the cursor pre filled
    nmap ,wG :execute ":Tags " . expand('<cword>')<CR>
    " general code finder in current file mapping
    nmap ,f :BLines<CR>
    " the same, but with the word under the cursor pre filled
    nmap ,wf :execute ":BLines " . expand('<cword>')<CR>
    " general code finder in all files mapping
    nmap ,F :Lines<CR>
    " the same, but with the word under the cursor pre filled
    nmap ,wF :execute ":Lines " . expand('<cword>')<CR>
    " commands finder mapping
    nmap ,c :Commands<CR>

" Jedi-vim ------------------------------
    " Disable autocompletion (using deoplete instead)
    let g:jedi#completions_enabled = 0
    
    " All these mappings work only for python code:
    " Go to definition
    let g:jedi#goto_command = ',d'
    " Find ocurrences
    let g:jedi#usages_command = ',o'
    " Find assignments
    let g:jedi#goto_assignments_command = ',a'
    " Go to definition in new tab
    nmap ,D :vertical split<CR>:call jedi#goto()<CR>


" Ack.vim ------------------------------
    " mappings
    nmap ,r :Ack 
    nmap ,wr :execute ":Ack " . expand('<cword>')<CR>

" Yankring -------------------------------
    let g:yankring_history_dir = '~/.config/nvim/tmp'
    let g:yankring_clipboard_monitor = 0

" Airline ------------------------------
    let g:airline_powerline_fonts = 0
    let g:airline_theme = 'bubblegum'
    let g:airline#extensions#whitespace#enabled = 0

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

let g:user_emmet_leader_key=' '

if vim_plug_just_installed
    :CocInstall coc-python
endif

function! LinterStatus() abort
  set statusline=
  set statusline+=%m
  set statusline+=\ %f
  set statusline+=%=
  set statusline+=\ %{LinterStatus()}
  let l:counts = ale#statusline#Count(bufnr(''))

  let l:all_errors = l:counts.error + l:counts.style_error
  let l:all_non_errors = l:counts.total - l:all_errors

  return l:counts.total == 0 ? '✨ all good ✨' : printf(
        \   '😞 %dW %dE',
        \   all_non_errors,
        \   all_errors
        \)
endfunction



let g:ale_linters = {
      \   'python': ['flake8', 'pylint'],
      \   'javascript': ['eslint'],
      \}

let g:ale_fixers = {
      \    'python': ['yapf', 'autopep8', 'isort'],
      \}

nmap <F7> :ALEFix<CR>
let g:ale_lint_on_save = 1
let g:ale_fix_on_save = 1

"colorscheme
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

let g:jupytext_fmt = 'py'

"airline symbols
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

let g:snips_author="Alexandre Castro"
let g:snips_email="im.alexandre07@gmail.com"
let g:snips_github="https://www.github.com/im-alexandre"

set completefunc=emoji#complete

let vim_markdown_preview_github=1
let vim_markdown_preview_use_xdg_open=1
let vim_markdown_preview_toggle=3 
let g:fzf_layout = { 'window': { 'width': 0.8, 'height': 0.8 } }
set mouse=a
