" instalação automática do Plug
"


let g:vim_home = expand('$HOME/.config/nvim')
let g:vim_plug_path = expand('~/.config/nvim/autoload/plug.vim')
let vim_plug_just_installed = 0
let g:vim_plugin_install = expand('$HOME/.config/nvim/plugged')

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

lua require'user.plugins'
lua require'user.settings'
lua require'user.keymappings'
lua require'user.cmp'
lua require'user.lsp'

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
    let g:NERDTreeWinSize=40

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

" Encontrar arquivos usando o Telescope
    nnoremap <leader>e <cmd>Telescope find_files<cr>
    nnoremap <leader>b <cmd>Telescope buffers<cr>
    nnoremap <leader>gb <cmd>Telescope git_branches<cr>
    nnoremap <leader>gg <cmd>Telescope git_commits<cr>
    nnoremap <leader>rg <cmd>Telescope live_grep<cr>
    nnoremap <leader>fh <cmd>Telescope help_tags<cr>



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
    else
        let g:webdevicons_enable = 0
    endif

" ALE for fixing
    "let g:ale_linters = {
          "\   'python': ['flake8',],
          "\   'javascript': ['eslint'],
          "\}

    "let g:ale_fixers = {
          "\    'python': ['yapf', 'autopep8', 'isort'],
          "\    'php': ['phpcbf'],
          "\    'javascript': ['eslint']
          "\}

    "nmap <F7> :ALEFix<CR>
    "let g:ale_lint_on_save = 1
    "let g:ale_fix_on_save = 0



"colorscheme
    let g:gruvbox_contrast_dark='hard'
    colorscheme gruvbox
    highlight Normal ctermbg=none
    highlight GruvboxYellowBold ctermbg=Black
    highlight GruvboxOrangeBold ctermbg=Black


"let g:snips_author="Alexandre Castro"
"let g:snips_email="im.alexandre07@gmail.com"
"let g:snips_github="https://www.github.com/im-alexandre"

let vim_markdown_preview_github=1
let vim_markdown_preview_use_xdg_open=1
let vim_markdown_preview_toggle=3
let g:mkdp_page_title = '${name}'
set mouse=a


:command! -nargs=1 GoTerm lua require'harpoon.term'.gotoTerminal(<args>)
set completeopt=menu,menuone,noselect
