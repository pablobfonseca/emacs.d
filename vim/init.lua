--[[
        _
 __   _(_)_ __ ___
 \ \ / / | '_ ` _ \
  \ V /| | | | | | |
   \_/ |_|_| |_| |_|

 File: init.lua
 Author: Pablo Fonseca <pablofonseca777@gmail.com>
 Description: VIM Rocks!
 Source: http://github.com/pablobfonseca/dotfiles
--]]

local cmd = vim.cmd -- to execute Vim commands e.g. cmd('pwd')
local fn = vim.fn -- to call Vim functions e.g. fn.bufnr()
local g = vim.g -- a table to access global variables
local opt = vim.opt -- to set options

g.mapleader = ","
g.maplocalleader = "-"

cmd 'filetype off'
cmd 'filetype plugin indent on'

cmd 'autocmd!'
opt.compatible = false

local function map(mode, lhs, rhs, opts)
   local options = {noremap = true}
   if opts then options = vim.tbl_extend('force', options, opts) end
   vim.api.nvim_set_keymap(mode, lhs, rhs, options)
end

local function t(str)
   return vim.api.nvim_replace_termcodes(str, true, true, true)
end

function _G.smart_enter()
   if vim.fn.pumvisible() == 1 then
      return vim.fn['coc#select_confirm']()
   else
      return t'<C-g>u'
   end
end

cmd 'packadd paq-nvim' -- load the package manager
local paq = require('paq-nvim').paq -- a convenient alias

--paq {'savq/paq-nvim', opt = true} -- paq-nvim manages itself
--paq {'shougo/deoplete-lsp'}
--paq {'shougo/deoplete.nvim', run = fn['remote#host#UpdateRemotePlugins']}
--paq {'nvim-treesitter/nvim-treesitter'}
--paq {'neovim/nvim-lspconfig'}
--paq {'ojroques/nvim-lspfuzzy'}
--paq {'nvim-lua/popup.nvim'}
--paq {'nvim-lua/plenary.nvim'}
--paq {'nvim-telescope/telescope.nvim'}
--paq {'nvim-treesitter/nvim-treesitter', run = fn[':TSUpdate']}
--paq {'nvim-telescope/telescope-fzf-native.nvim', run = fn['make']}
--paq {'kyazdani42/nvim-web-devicons'}
--paq {'lewis6991/gitsigns.nvim'}
--g['deoplete#enable_at_startup'] = 1 -- enable deoplete at startup

map('c', '<C-k>', '<up>')
map('c', '<C-j>', '<down>')

map('c', '<C-x><C-e>', '<C-e><C-f>')
map('c', '%%', '<C-R>=expand("%:h")."/"<cr>')

-- Enable indent folding
opt.foldenable = true
opt.foldmethod = 'indent'
opt.foldlevel = 999

-- Quick fold to level 1, especially useful for Coffeescript class files
map('n', '<leader>fld', '<cmd>set foldlevel=1<cr>')

-- Maps for folding, unfolding all
map('n', '<leader>fu', 'zM<CR>')
map('n', '<leader>uf', 'zR<CR>')

-- Maps for setting foldleve
map('n', '<leader>fl1', '<cmd>set foldlevel=1<cr>')
map('n', '<leader>fl2', '<cmd>set foldlevel=2<cr>')
map('n', '<leader>fl3', '<cmd>set foldlevel=3<cr>')
map('n', '<leader>fl4', '<cmd>set foldlevel=4<cr>')

-- Focus the current fold by closing all others
map('n', '<leader>flf', 'mzzM`zzv')

-- Set foldlevel to match current line
map('n', '<leader>flc', '<cmd>execute "set foldlevel=" . foldlevel(".")<cr>')

-- Creates a floating window with a most recent buffer to be used
  vim.api.nvim_exec([[
    function! CreateCenteredFloatingWindow()
      if has('nvim')
        let width = float2nr(&columns * 0.8)
        let height = float2nr(&lines * 0.8)
        let top = ((&lines - height) / 2) - 1
        let left = (&columns - width) / 2
        let opts = {'relative': 'editor', 'row': top, 'col': left, 'width': width, 'height': height, 'style': 'minimal'}

        let top = '╭' . repeat('─', width - 2) . '╮'
        let mid = '│' . repeat(' ', width - 2) . '│'
        let bot = '╰' . repeat('─', width - 2) . '╯'
        let lines = [top] + repeat([mid], height - 2) + [bot]
        let s:buf = nvim_create_buf(v:false, v:true)
        call nvim_buf_set_lines(s:buf, 0, -1, v:true, lines)
        call nvim_open_win(s:buf, v:true, opts)
        set winhl=Normal:Floating
        let opts.row += 1
        let opts.height -= 2
        let opts.col += 2
        let opts.width -= 4
        call nvim_open_win(nvim_create_buf(v:false, v:true), v:true, opts)
        autocmd BufWipeout <buffer> call CleanupBuffer(s:buf)
        tnoremap <buffer> <silent> <Esc> <C-\><C-n><CR>:call DeleteUnlistedBuffers()<CR>
      endif
    endfunction

    function! OnTermExit(job_id, code, event) dict
      if has('nvim')
        if a:code == 0
          call DeleteUnlistedBuffers()
        endif
      endif
    endfunction

    function! DeleteUnlistedBuffers()
      if has('nvim')
        for n in nvim_list_bufs()
          if ! buflisted(n)
            let name = bufname(n)
            if name == '[Scratch]' ||
                  \ matchend(name, ':bash') ||
                  \ matchend(name, ':zsh')
              call CleanupBuffer(n)
            endif
          endif
        endfor
      endif
    endfunction

    function! CleanupBuffer(buf)
      if has('nvim')
        if bufexists(a:buf)
          silent execute 'bwipeout! '.a:buf
        endif
      endif
    endfunction

    function! ToggleTerm(cmd)
      if has('nvim')
        if empty(bufname(a:cmd))
          call CreateCenteredFloatingWindow()
          call termopen(a:cmd, { 'on_exit': function('OnTermExit') })
        else
          call DeleteUnlistedBuffers()
        endif
      endif
    endfunction

    function! ToggleScratchTerm()
      if has('nvim')
        call ToggleTerm('zsh')
      endif
    endfunction
    command! ToggleScratchTerm call ToggleScratchTerm()

    " When term starts, auto go into insert mode
    if has('nvim')
      autocmd TermOpen * startinsert

      " Turn off line numbers etc
      autocmd TermOpen * setlocal listchars= nonumber norelativenumber
    endif

    " Remove current file - Extracted from tpope's vim-eunuch plugin
    command! -bar -bang Remove
          \ let s:file = fnamemodify(bufname(<q-args>),':p') |
          \ execute 'bdelete<bang>' |
          \ if !bufloaded(s:file) && delete(s:file) |
          \   echoerr 'Failed to delete "'.s:file.'"' |
          \ endif |
          \ unlet s:file

    " Handles closing in cases where you would be the last window
    function! CloseWindowOnSuccess(code) abort
      if a:code == 0
        let current_window = winnr()
        bdelete!
        " Handles special cases where window remains due startify
        if winnr() == current_window
          close
        endif
      endif
    endfunction

    " Open autoclosing terminal, with optional size and dir
    function! OpenTerm(cmd) abort
      if has('nvim')
        call termopen(a:cmd, {'on_exit': { _, c -> CloseWindowOnSuccess(c) }})
      else
        call term_start(a:cmd, {'exit_cb': {_, c -> CloseWindowOnSuccess(c)}})
      endif
      setf openterm
    endfunction

    " Open vsplit with animation
    function! OpenVTerm(cmd, percent) abort
      if has('nvim')
        vnew
      endif
      call OpenTerm(a:cmd)
      wincmd L | vertical resize 1
      call animate#window_percent_width(a:percent)
    endfunction

    function! OpenHTerm(cmd, percent) abort
      if has('nvim')
        new
      endif
      call OpenTerm(a:cmd)
      wincmd J | resize 1
      call animate#window_percent_height(a:percent)
    endfunction
]], true)

opt.hidden = true                              -- Allow buffer change w/o saving
opt.autoread = true                            -- Load file from disk, ie for git reset
opt.compatible = false                         -- Not concerned with vi compatibility
opt.lazyredraw = true                          -- Don't update while executing macros
opt.backspace = {'indent', 'eol', 'start'}     -- Sane backspace behavior
opt.history = 1000                             -- Remember last 1000 commands
opt.scrolloff = 7                              -- Start scrolling when we're 7 lines away from margins
opt.mouse = ''
opt.expandtab = true                           -- Convert <tab> to spaces (2 or 4)
opt.tabstop = 2                                -- Two spaces per tab as default
opt.shiftwidth = 2                             -- Then override with per filteype
opt.softtabstop = 2                            -- Specific settings via autocmd
opt.secure = true                              -- Limit what modelines and autocmds can do
opt.autowrite = true                           -- Write for me when I take any action
opt.autoindent = true
opt.copyindent = true
opt.textwidth = 79
opt.rtp:append({'/usr/local/opt/fzf'})
opt.cmdheight = 2
opt.formatoptions:remove({'cro'})              -- Stop vim to keep adding comments on carriage return
opt.relativenumber = true
opt.number = true
opt.re = 1
opt.nrformats:append({'alpha'})                -- Force decimal-based arithmetic
opt.shortmess:append({A = true, c = true})     -- don't give |ins-completion-menu| messages
opt.updatetime = 300                           -- You will have a bad experience for diagnostic messages when it's default 4000
opt.signcolumn = 'yes'                         -- always show signcolumns
opt.shell = '/bin/zsh'                         -- Set zsh as default shell
opt.showmatch = true                           -- jump to matches when entering regexp
opt.isfname:remove({':'})
opt.termguicolors = true
opt.inccommand = 'nosplit'                     -- substitute with preview

g.netrw_fastbrowse = 0                         -- Fix netrw buffer issue

-- Set modeline to 1 to allow rcfiles to be recognized as vim files
opt.modelines = 1

-- Disable swap files
opt.backup = false
opt.writebackup = false
opt.swapfile = false

-- Completions
opt.completeopt:append({'menuone', 'noinsert'})
opt.completeopt:remove({'longest', 'preview', 'menu', 'noselect'})

-- Setup nice command tab completion
opt.wildmenu = true
opt.wildmode= {'list:longest','full'}
opt.wildignore:append({'*/tmp/*','*.so','*.swp','*.zip','*.pyc'})

-- Persistent undo
local undodir = fn.expand('~/.undo-vim')
if not fn.isdirectory(undodir) then
   fn.mkdir(undodir)
end

opt.undodir = {'~/.undo-vim'}
opt.undofile = true -- Create FILE.un~ files for persistent undo

opt.shiftround = true -- When at 3 spaces and I hit >>, go to 4, not 5.

-- (Hopefully) removes the delay when hitting esc in insert mode
opt.ttimeout = true
-- Don't wait so long for the next keypress (particularly in ambigious Leader situations.
opt.timeoutlen = 500

-- Golang config

cmd 'augroup filetype_go'
-- Clear old autocmds in group
cmd 'autocmd!'
-- autoindent with two spaces, always expand tabs
cmd  'autocmd BufNewFile,BufRead *.go setlocal ai sw=4 ts=4 sts=4 et fileformat=unix'
cmd  'autocmd Filetype go nmap <leader>r :GoRun <cr><Esc>'
cmd  'autocmd Filetype go nmap <leader>t <Plug>(go-test)'
cmd  'autocmd Filetype go nmap <leader>c <Plug>(go-coverage-toggle)'
cmd  'autocmd Filetype go nmap <leader>b :<C-u>call <SID>build_go_files()<cr>'
cmd 'augroup END'

g.go_fmt_command = "goimports"
g.go_highlight_functions = 1
g.go_highlight_methods = 1
g.go_highlight_fields = 1
g.go_highlight_types = 1
g.go_highlight_operators = 1
g.go_highlight_build_constraints = 1

-- run :GoBuild or :GoTestCompile based on the go file
vim.api.nvim_exec(
   [[
function! BuildGoFiles()
  let l:file = expand("%")
  if l:file =~# '^\f\+_test\.go$'
    call go#test#Test(0, 1)
  elseif l:file =~# '^\f\+\.go$'
    call go#cmd#Build(0)
  endif
endfunction]],true)

-- Haskell config

cmd 'augroup filetype_haskell'
  -- Clear old autocmds in group
  cmd 'autocmd!'
  cmd 'autocmd FileType haskell nnoremap <leader>hr :Dispatch runhaskell %<tab><cr>'
  cmd 'autocmd FileType haskell nnoremap <leader>hb :Dispatch ghc %<tab><cr>'
cmd 'augroup END'

-- HTML config

cmd 'augroup filetype_html'
  -- Clear old autocmds in group
  cmd 'autocmd!'
  -- Install Emmet
  cmd 'autocmd FileType html,css EmmetInstall'
cmd 'augroup END'

-- Javascript config

cmd 'augroup filetype_javascript'
  -- Clear old autocmds in group
  cmd 'autocmd!'
  -- Set syntax javascript to coffee script files
  cmd 'autocmd FileType javascript nnoremap <leader>r :Dispatch node %<cr>'
  cmd 'autocmd FileType javascript.jsx set ft=javascript'
cmd 'augroup END'

-- JSON config
  cmd 'augroup filetype_json'
    -- Clear old autocmds in group
    cmd 'autocmd!'
    -- autoindent with two spaces, always expand tabs
    cmd 'autocmd Filetype json nmap <leader>p :w<cr> :PrettyJSON<cr> :w<cr>'
  cmd 'augroup END'

  -- Requires 'jq' (brew install jq)
  vim.api.nvim_exec(
  [[
    function! PrettyJSON()
      %!jq .
      set filetype=json
    endfunction
    ]],true)
  vim.api.nvim_command('command! PrettyJSON :call PrettyJSON()')

-- Lua config

cmd 'augroup filetype_lua'
  -- Clear old autocmds in group
  cmd 'autocmd!'
  cmd 'autocmd FileType lua nnoremap <leader>r :Dispatch lua %<Tab><cr>'
cmd 'augroup END'

-- Markdown config

cmd 'augroup filetype_markdown_and_txt'
  -- Clear old autocmds in group
  cmd 'autocmd!'
  -- By default, vim thinks .md is Modula-2.
  cmd 'autocmd BufNewFile,BufReadPost *.md set filetype=markdown'
  cmd 'autocmd FileType pad-notes set filetype=markdown'
  -- Without this, vim breaks in the middle of words when wrapping
  cmd 'autocmd FileType markdown setlocal nolist wrap lbr'
  -- Turn on spell-checking in markdown and text.
  cmd 'autocmd BufRead,BufNewFile *.md,*.txt setlocal spell'
  -- Don't display whitespaces
  cmd 'autocmd BufNewFile,BufRead *.txt setlocal nolist'
cmd 'augroup END'

-- Python config

g.python_host_prog = '/usr/bin/python'
g.python3_host_prog = '/opt/homebrew/bin/python3'

cmd 'augroup filetype_python'
  -- Clear old autocmds in group
  cmd 'autocmd!'
  cmd 'autocmd BufNewFile,BufRead *.py setlocal ai sw=4 ts=4 sts=4 et fileformat=unix'
  cmd 'autocmd FileType python nnoremap <leader>py :Dispatch python3 %<Tab><cr>'
  cmd 'autocmd FileType python nnoremap <leader>pt :TestFile<cr>'
  cmd [[autocmd BufWritePre *.py :%s/\s\+$//e]]
cmd 'augroup END'

-- Ruby config

g.ruby_path = fn.system('rvm current')
g.ruby_operators = 1

cmd 'augroup filetype_ruby'
  -- Clear old autocmds in group
  cmd 'autocmd!'
  -- autoindent with two spaces, always expand tabs
  cmd 'autocmd FileType rspec set filetype=ruby'
  cmd 'autocmd FileType ruby,eruby,yaml setlocal ai sw=2 sts=2 et'
  cmd 'autocmd FileType ruby,eruby,yaml setlocal path+=lib'
  -- Make ?s part of words
  cmd 'autocmd FileType ruby,eruby,yaml setlocal iskeyword+=?'
  cmd 'autocmd FileType gitcommit setlocal spell textwidth=72'
  -- Run the current ruby file
  cmd 'autocmd FileType ruby nnoremap <leader>r :Dispatch ruby %<cr>'
  -- Generage tags for ruby files
  cmd 'autocmd FileType ruby nnoremap <Leader>rt :!ctags -R --languages=ruby --exclude=.git --exclude=log .<cr>'
  -- Remove trailing whitespace on save for ruby files.
  cmd [[autocmd BufWritePre *.rb :%s/\s\+$//e]]
  cmd 'autocmd BufRead,BufNewFile {Vagrantfile,Gemfile,Guardfile,Thorfile,Procfile,config.ru,*.rake,.pryrc} set filetype=ruby'
  -- Set .erb html files
  cmd 'autocmd FileType eruby setlocal sw=2 sts=2 ts=2' -- Two spaces per tab

  -- Setting for vim-dispatch
  cmd([[
    autocmd FileType ruby
        \ let b:start = executable('pry') ? 'pry -r "%:p"' : 'irb -r "%:p"' |
        \ if expand('%') =~# '_spec\.rb$' |
        \   let b:dispatch = 'rspec %' |
        \ elseif expand('%') =~# '_test\.rb$' |
        \   let b:dispatch = 'ruby -Ilib:test %' |
        \ elseif !exists('b:dispatch') |
        \   let b:dispatch = 'ruby -wc %' |
        \ endif
]])

  -- Clean comments
  cmd 'autocmd FileType ruby nnoremap <leader>cc :g/#/d<cr>'
  map('n', '<Leader>t', '<cmd>w<cr>:call RunTest("TestFile")<cr>')
  map('n', '<Leader>s', '<cmd>call RunTest("TestNearest")<cr>')
  map('n', '<Leader>a', '<cmd>call RunTest("TestSuite")<cr>')
  map('n', '<Leader>l', '<cmd>call RunTest("TestLast")<cr>')
  map('n', '<leader>or', '<cmd>tabe config/routes.rb<cr>')
  map('n', '<leader>ol', '<cmd>tabe config/locales<cr>')
cmd 'augroup END'

-- Rust config

cmd 'augroup filetype_rust'
  -- Clear old autocmds in group
  cmd 'autocmd!'
  cmd 'autocmd FileType rust nnoremap <leader>cr :Cargo run<cr>'
  cmd 'autocmd FileType rust nnoremap <leader>cb :Cargo build<cr>'
cmd 'augroup END'

-- SQL config

cmd 'augroup filetype_sql'
  -- Clear old autocmds in group
  cmd 'autocmd!'

  cmd 'autocmd FileType sql call SqlFormatter()'
cmd 'augroup END'

vim.api.nvim_exec([[
function SqlFormatter()
  set noai

  map ,pt :%!sqlformat --reindent --keywords upper --identifiers lower -<CR>
endfunction
]], true)

-- Helpfiles

cmd 'au filetype help call HelpFileMode()'

vim.api.nvim_exec([[
    function! HelpFileMode()
      wincmd T " Maximze the help on open
      nnoremap <buffer> <tab> :call search('\|.\{-}\|', 'w')<cr>:noh<cr>2l
      nnoremap <buffer> <S-tab> F\|:call search('\|.\{-}\|', 'wb')<cr>:noh<cr>2l
      nnoremap <buffer> <cr> <c-]>
      nnoremap <buffer> <bs> <c-T>
      nnoremap <buffer> q :q<CR>
      setlocal nonumber
      setlocal nospell
    endfunction
]], true)

map('n', '<leader>rh', '<cmd>h local-additions<cr>')

-- Mappings

-- Emacs-like mappings
map('n', '<C-x><C-s>', '<cmd>w<cr>')
map('n', '<C-x><C-c>', '<cmd>x<cr>')
map('n', '<C-s>', '/')
map('n', '<C-c>pf', '<cmd>FzfFiles<cr>')
map('n', '<C-x>1', '<cmd>only<cr>')
map('n', '<C-x>2', '<cmd>split<cr>')
map('n', '<C-x>3', '<cmd>vsplit<cr>')
map('n', '<C-x>0', '<cmd>q<cr>')

function _G.show_documentation()
   if fn.index({'vim', 'help'}, vim.bo.filetype) >= 0 then
      vim.api.nvim_command('execute "h ".expand("<cword>")')
   else
      vim.api.nvim_command('call CocActionAsync("doHover")')
   end
end

map('n', 'H', 'v:lua.show_documentation()', { noremap = true, silent = true})
map('n', 'K', '<cmd>Rg <C-R><C-W><cr>', { noremap = true, silent = true})

-- Opens help the word under the cursor
map('n', '<leader>h', '<cmd>exe "help" expand("<cword>")<cr>')

-- select last paste in visual mode
map('n', 'gp', '`[v`]')

-- Change vertically split to horizonally
map('n', '<leader>fh', '<C-w>t<C-w>K')

-- Change horizonally split to vertically
map('n', '<leader>fv', '<C-w>t<C-w>H')

-- Make Y yank to end of line (like D, or C)
map('n', 'Y', 'y$')

-- Insert a caller into Ruby code
map('n', '<leader>wtf', 'oputs "#" * 90<c-m>puts caller<c-m>puts "#" * 90<esc>')

-- Source vimrc
map('n', '<leader>sv', '<cmd>source ~/.vim/init.lua<cr>')

-- Toggle paste mode on and off
map('n', '<leader>pp', '<cmd>set paste<cr>o<esc>"*]p:set nopaste<cr>')

map('n', ';', ':')

-- Indent the whole file
map('n', '<Leader>i', 'mmgg=G`m')

-- Edit another file in the same directory as the current file
-- uses expression to extract path from current file's path
map('n', '<space>e', '<cmd>e <C-R>=escape(expand("%:p:h")," ") . "/"<CR>')
map('n', '<C-x><C-f>', '<cmd>e <C-R>=escape(expand("%:p:h")," ") . "/"<CR>')
map('n', '<space>s', '<cmd>split <C-R>=escape(expand("%:p:h"), " ") . "/"<CR>')
map('n', '<space>v', '<cmd>vsplit <C-R>=escape(expand("%:p:h"), " ") . "/"<CR>')
map('n', '<space>r', '<cmd>r <C-R>=escape(expand("%:p:h"), " ") . "/"<CR>')
map('n', '<space>t', '<cmd>tabe <C-R>=escape(expand("%:p:h"), " ") . "/"<CR>')
map('n', '<space>sav', '<cmd>sav <C-R>=escape(expand("%:p:h"), " ") . "/"<CR>')

-- Use j/k to start, then scroll through autocomplete options
map('i', '<expr> <C-j>', [[((vim.fn.pumvisible())?("\<C-n>"):("\<C-x><c-n>"))]])
map('i', '<expr> <C-k>', [[((vim.fn.pumvisible())?("\<C-p>"):("\<C-x><c-k>"))]])

-- Close the quickfix window
map('n', '<space><space>', '<cmd>ccl<cr>')

-- Increase and decrease numbers
map('n', '<C-b>', '<C-a>')

-- Let's be reasonable, shall we?
map('n', 'k', 'gk')
map('n', 'j', 'gj')

-- Visual mode pressing * or # searches for the current selection
-- Super useful! From an idea by Michael Naumann
map('v', '<silent> *', '<cmd>call VisualSelection("f")<CR>')

-- When you press <leader>r you can search and replace the selected text
map('v', '<silent> <leader>r', '<cmd>call VisualSelection("replace")<CR>')

-- Disable arrows
for _,prefix in pairs({ 'i', 'n', 'v' }) do
   for _,key in pairs({ '<Up>', '<Down>', '<Left>', '<Right>' }) do
      map(prefix, key, '<Nop>')
   end
end

-- resize panes
map('n', '<silent> <Up>', '<cmd>call animate#window_delta_height(15)<cr>')
map('n', '<silent> <Down>', '<cmd>call animate#window_delta_height(-15)<cr>')
map('n', '<silent> <Left>', '<cmd>call animate#window_delta_width(30)<cr>')
map('n', '<silent> <Right>', '<cmd>call animate#window_delta_width(-30)<cr>')

-- Scroll the viewport faster
map('n', '<C-e>', '7<C-e>')
map('n', '<C-y>', '7<C-y>')
map('v', '<C-e>', '7<C-e>')
map('v', '<C-y>', '7<C-y>')

-- Disable mouse scroll wheel
map('n', '<ScrollWheelUp>', '<nop>')
map('n', '<S-ScrollWheelUp>', '<nop>')
map('n', '<C-ScrollWheelUp>', '<nop>')
map('n', '<ScrollWheelDown>', '<nop>')
map('n', '<S-ScrollWheelDown>', '<nop>')
map('n', '<C-ScrollWheelDown>', '<nop>')
map('n', '<ScrollWheelLeft>', '<nop>')
map('n', '<S-ScrollWheelLeft>', '<nop>')
map('n', '<C-ScrollWheelLeft>', '<nop>')
map('n', '<ScrollWheelRight>', '<nop>')
map('n', '<S-ScrollWheelRight>', '<nop>')
map('n', '<C-ScrollWheelRight>', '<nop>')

-- Open Gemfile
map('n', '<leader>og', '<cmd>e Gemfile<cr>')

-- Jump to start and end of line using the home row keys
map('n', '0', '^')

-- Tab/shift-tab to indent/outdent in visual mode.
map('v', '<Tab>', '>gv')
map('v', '<S-Tab>', '<gv')

-- Quickly browse to any tag/symbol in the project
map('n', '<leader>ot', '<cmd>tag<space>')

-- Save file as sudo
map('c', 'w!!', '<cmd>w !sudo tee % >/dev/null')

-- Move split to tab
map('n', '<leader>mt', '<c-w><s-t>')

-- Map to increment and decrement
map('n', '+', '<C-a>')
map('n', '-', '<C-x>')
map('x', '+', 'g<C-a>')
map('x', '-', 'g<C-x>')

-- Open Lazygit
map('n', '<leader>tlg', '<cmd>call OpenHTerm("lazygit", 0.8)<cr>')
-- Open Lazydocker
map('n', '<leader>tld', '<cmd>call OpenHTerm("lazydocker", 0.8)<cr>')

-- Correct previous misspelled word ( Don't forgot to set spell )
map('n', '<space>sp', 'mm[s1z=`m')

-- Remote yank

      map('n', '<leader>li', '<cmd>call RemoteYank("i")<cr>')
      map('n', '<leader>la', '<cmd>call RemoteYank("a")<cr>')
      map('n', '<leader>lr', '<cmd>call RemoteYank("r")<cr>')

    vim.api.nvim_exec([[
      function! RemoteYank(dir)
        if &relativenumber
          echom "setting number"
          let was_relative = 1
          set number
          redraw!
        endif

        echohl String | let line = input("Remote link to yank: ") | echohl None
        if line == '' | return | endif

        execute line.'yank a'
        if a:dir == 'i'
          normal "aP
        elseif a:dir == 'a'
          normal "ap
        else
          normal V"ap
        endif

        if was_relative
          set relativenumber
        endif
      endfunction
  ]], true)

-- Search

opt.hlsearch = true                    -- highlight searches, map below to clear
opt.incsearch = true                   -- do incremental searching
opt.ignorecase = true                  -- Case insensitive...
opt.smartcase = true                   -- ...except if you use UCase

map('n', '<silent><leader><space>', '<cmd>nohl<cr>')

-- quick searching of vimrc files
vim.api.nvim_exec([[
function! VimrcSearch()
  echohl String | let text = input("Text to search: ") | echohl None
  if text == '' | return | endif
  execute "Rg ". text ." ~/.emacs.d/vim/init.lua"
endfunction
]], true)
vim.api.nvim_command("command! VimrcSearch call <sid>VimrcSearch()")
map('n', '<leader>sr', '<cmd>VimrcSearch<cr>')

-- Mappings for quick search & replace. Global set to default
-- Do a / search first, then leave pattern empty in :s// to use previous
map('n', '<Leader>sub', [[:%s///g<left><left>]])
map('v', '<Leader>sub', [[:s///g<left><left>]])
map('n', '<leader>wub', [[:%s//<C-r><C-w>/g<cr>]])

map('n', 'Q', '@q')
map('v', 'Q', '<cmd>normal Q<cr>')

-- Statusline

-- Use this to prevent some settings from reloading
g.vimrc_loaded = 1

opt.laststatus=2 -- Always show the statusline

-- define 3 custom highlight groups
vim.api.nvim_command("hi User1 ctermbg=lightgray ctermfg=yellow guifg=orange guibg=#444444 cterm=bold gui=bold")
vim.api.nvim_command("hi User2 ctermbg=lightgray ctermfg=red guifg=#dc143c guibg=#444444 gui=none")
vim.api.nvim_command("hi User3 ctermbg=lightgray ctermfg=red guifg=#ffff00 guibg=#444444 gui=bold")

opt.statusline=''

opt.statusline = '%*'
opt.statusline:append("%{InsertSpace()}")

opt.statusline:append("%1*")
opt.statusline:append("%{HasPaste()}")
opt.statusline:append("%*")

opt.statusline:append("%-40f ")

opt.statusline:append("%2*")
opt.statusline:append("%m")

opt.statusline:append("%*")
opt.statusline:append("%r")
opt.statusline:append("%h")

opt.statusline:append("%*")
opt.statusline:append([[  %y]])

opt.statusline:append("%=")
opt.statusline:append("%{SlSpace()}")
opt.statusline:append("  Col:%c")
opt.statusline:append("  Line:%l/%L")
opt.statusline:append("  %P%{InsertSpace()}")

vim.api.nvim_exec([[
  function! SlSpace()
    if exists("*GetSpaceMovement")
      return "[" . GetSpaceMovement() . "]"
    else
      return ""
    endif
  endfunc

  function! InsertSpace()
    " For adding trailing spaces onto statusline
    return ' '
  endfunction

  function! HasPaste()
    if &paste
      return '[PASTE]'
    else
      return ''
    endif
  endfunction

  function! CurDir()
    let curdir = substitute(getcwd(), '/Users/pablobfonseca/', "~/", "g")
    return curdir
  endfunction
]], true)

-- Tags

opt.tags:prepend({"./.git/tags"})

-- Terminal config

cmd 'augroup terminal'
  -- Clear old autocmds in group
  cmd 'autocmd!'

  cmd 'autocmd BufEnter * if &buftype == "terminal" | :startinsert | endif'

  -- Quit term buffer with Esc
  map('t', '<silent> <Esc>', [[<C-\><C-n><cr>]])

  -- use alt+hjkl to move between split/vsplit panels
  map('t', '<c-h>', [[<C-\><C-n><C-w>h]])
  map('t', '<c-j>', [[<C-\><C-n><C-w>j]])
  map('t', '<c-k>', [[<C-\><C-n><C-w>k]])
  map('t', '<c-l>', [[<C-\><C-n><C-w>l]])

  vim.api.nvim_exec([[
    function! OpenTerminal()
      split | terminal
      split term:///bin/zsh
      resize 10
    endfunction
  ]], true)
  -- Open Terminal on Ctrl+n
  map('n', '<C-x>n', '<cmd>call OpenTerminal()<cr>')
cmd 'augroup END'

-- Vim config

    cmd 'augroup vim_stuff'
      -- Clear old autocmds in group
      cmd 'autocmd!'
      -- automatically rebalance windows on vim resize
      cmd 'autocmd VimResized * :wincmd ='
      -- Execute the vim current vim command line
      cmd 'autocmd Filetype vim nnoremap <leader>x :execute getline(".")<cr>'

      -- Wrap the quickfix window
      cmd 'autocmd FileType qf setlocal wrap linebreak'
      cmd 'autocmd BufWritePre * :call MkNonExDir(expand("<afile>"), +expand("<abuf>"))'
      cmd 'autocmd BufWinEnter *.txt if &ft == "help" | wincmd L | endif'
    cmd 'augroup END'

    -- Functions

  vim.api.nvim_exec([[
    function! RenameFile()
      let old_name = expand('%')
      let new_name = input('New file name: ', expand('%'), 'file')
      if new_name != '' && new_name != old_name
        exec ':saveas ' . new_name
        exec ':silent !rm ' . old_name
        redraw!
      endif
    endfunction
  ]], true)
  map('n', '<Leader>rr', '<cmd>call RenameFile()<cr>')

  vim.api.nvim_exec([[
  function! CmdLine(str)
    exe "menu Foo.Bar :" . a:str
    emenu Foo.Bar
    unmenu Foo
  endfunction

    function! VisualSelection(direction) range
      let l:saved_reg = @"
      execute "normal! vgvy"

      let l:pattern = escape(@", '\\/.*$^~[]')
      let l:pattern = substitute(l:pattern, "\n$", "", "")

      if a:direction == 'b'
        execute "normal ?" . l:pattern . "^M"
      elseif a:direction == 'gv'
        call CmdLine("vimgrep " . '/'. l:pattern . '/' . ' **/*.')
      elseif a:direction == 'replace'
        call CmdLine("%s" . '/'. l:pattern . '/')
      elseif a:direction == 'f'
        execute "normal /" . l:pattern . "^M"
      endif

      let @/ = l:pattern
      let @" = l:saved_reg
    endfunction

    function! MkNonExDir(file, buf)
      if empty(getbufvar(a:buf, '&buftype')) && a:file!~#'\v^\w+\:\/'
        let dir=fnamemodify(a:file, ':h')
        if !isdirectory(dir)
          call mkdir(dir, 'p')
        endif
      endif
    endfunction

    function! AlignSection(regex) range
      let extra = 1
      let sep = empty(a:regex) ? '=' : a:regex
      let maxpos = 0
      let section = getline(a:firstline, a:lastline)
      for line in section
        let pos = match(line, ' *'.sep)
        if maxpos < pos
          let maxpos = pos
        endif
      endfor
      call map(section, 'AlignLine(v:val, sep, maxpos, extra)')
      call setline(a:firstline, section)
    endfunction
    command! -nargs=? -range Align <line1>,<line2>call AlignSection('<args>')

    function! AlignLine(line, sep, maxpos, extra)
      let m = matchlist(a:line, '\(.\{-}\) \{-}\('.a:sep.'.*\)')
      if empty(m)
        return a:line
      endif
      let spaces = repeat(' ', a:maxpos - strlen(m[1]) + a:extra)
      return m[1] . spaces . m[2]
    endfunction

    " TODO: Create a function to search gems right from vim
    function! SearchForCallSitesCursor()
      let searchTerm = expand("<cword>")
      call SearchForCallSites(searchTerm)
    endfunction

    " Search for call sites for term (excluding its definition) and
    " load into the quickfix list.
    function! SearchForCallSites(term)
      cexpr system('ag ' . shellescape(a:term) . '\| grep -v def')
    endfunction
  ]], true)

map('v', '<silent> <Leader>al', '<cmd>Align<CR>')

-- Visual config

  cmd 'colorscheme vendetta'

  opt.visualbell = true

  -- Easy access to maximizing
  map('n', '<C-_>', '<C-w>_')

  opt.splitbelow = true
  opt.splitright = true

  -- Colors
  vim.api.nvim_command('hi Search guifg=#000000 guibg=#8dabcd guisp=#8dabcd gui=NONE ctermfg=NONE ctermbg=110 cterm=NONE')
  vim.api.nvim_command('hi WarningMsg guifg=#bd4848 guibg=#f9f8ff guisp=#f9f8ff gui=bold ctermfg=131 ctermbg=15 cterm=bold')
  vim.api.nvim_command('hi ErrorMsg guifg=#bd5353 guibg=NONE guisp=NONE gui=NONE ctermfg=131 ctermbg=NONE cterm=NONE')

  -- Make it more obvious which paren I'm on
  vim.api.nvim_command('hi MatchParen cterm=none ctermbg=black ctermfg=yellow')

  vim.api.nvim_command('hi! link Search CursorLine')
  vim.api.nvim_command('hi! link SpellBad ErrorMsg')
  vim.api.nvim_command('hi! link SpellCap ErrorMsg')
  vim.api.nvim_command('hi! link Error ErrorMsg')

  map('n', '<leader>!', '<cmd>redraw!<cr>')

  -- zoom a vim pane, <C-w>= to re-balance
  map('n', '<leader>-', [[<cmd>wincmd _<cr>:wincmd \|<cr>]])
  map('n', '<leader>=', '<cmd>wincmd =<cr>')

-- Zsh config

cmd 'augroup filetype_zsh'
  -- Clear old autocmds in group
  cmd 'autocmd!'
  -- set shell syntax for zsh files
  cmd 'autocmd FileType zsh set syntax=sh'
  cmd 'autocmd BufRead,BufNewFile *.zsh-theme set filetype=zsh'
cmd 'augroup END'

vim.api.nvim_command([[command! ReformatCurlRequest silent %s/\s\(-.\{-}\)\s/ \1 /g]])

cmd 'packadd paq-nvim' -- load the package manager
local paq = require('paq-nvim').paq -- a convenient alias
paq {'savq/paq-nvim', opt = true} -- paq-nvim manages itself
paq {'nvim-lua/popup.nvim'}
paq {'nvim-lua/plenary.nvim'}
paq {'kyazdani42/nvim-web-devicons'}

paq {'marcweber/vim-addon-mw-utils'}

paq {'dense-analysis/ale'}

g.ale_linters = { javascript = {'xo'} }
g.ale_fixers = { javascript = {'xo'} }

paq {'camspiers/animate.vim'}

g['animate#easing_func'] = 'animate#ease_out_quad'

paq {'pechorin/any-jump.vim'}

paq {'neoclide/coc.nvim', branch = 'release'}

g.coc_global_extensions = {'coc-snippets', 'coc-pairs', 'coc-emmet', 'coc-tsserver', 'coc-json', 'coc-solargraph', 'coc-css', 'coc-python'}

-- Remap keys for gotos
map('n', '<silent> gd', '<Plug>(coc-definition)')
map('n', '<silent> gy', '<Plug>(coc-type-definition)')
map('n', '<silent> gi', '<Plug>(coc-implementation)')
map('n', '<silent> gr', '<Plug>(coc-references)')
map('n', '<silent> [g', '<Plug>(coc-diagnostic-prev)')
map('n', '<silent> ]g', '<Plug>(coc-diagnostic-next)')

map('i', '<silent><cr>', 'v:lua.smart_enter()', {expr = true, noremap = true})

vim.api.nvim_exec([[
              function! CheckBackSpace() abort
                let col = col('.') - 1
                return !col || getline('.')[col - 1]  =~# '\s'
              endfunction
              ]], true)

function _G.smart_tab()
   if vim.fn.pumvisible() == 1 then
      return t'<C-n>'
   elseif vim.fn['CheckBackSpace']() == 1 then
      return t'<TAB>'
   else
      return vim.fn['coc#refresh']()
   end
end

function _G.smart_s_tab()
   if vim.fn.pumvisible() == 1 then
      return t'<C-p>'
   else
      return t'<C-h>'
   end
end

map('i', '<TAB>', 'v:lua.smart_tab()', {expr = true, noremap = true})
map('i', '<S-TAB>', 'v:lua.smart_s_tab()', {expr = true, noremap = true})

paq {'neoclide/coc-neco'}

paq {'tpope/vim-commentary'}

map('v', 'cm', '<Plug>Commentary')
map('v', '<M-/>', '<Plug>Commentary')
map('n', 'cm', '<Plug>Commentary')
map('n', 'cml', '<Plug>CommentaryLine')
map('n', '<M-/>', '<Plug>CommentaryLine')

paq {'junegunn/vim-easy-align'}

map('v', '<leader>ea', '<Plug>(EasyAlign)')
map('x', 'ga', '<Plug>(EasyAlign)')
map('n', 'ga', '<Plug>(EasyAlign)')

paq {'easymotion/vim-easymotion'}

g.EasyMotion_leader_key = '<leader><leader>'

paq {'mattn/emmet-vim'}

g.user_emmet_leader_key = '<C-Z>'
g.user_emmet_settings = { ["javascript.jsx"] = { extends = 'jsx'} }
g.user_emmet_mode = 'a'

paq {'tpope/vim-endwise'}

paq {'tpope/vim-fugitive'}

map('n', '<leader>st', '<cmd>call SaveSessionAndShowGitStatus()<cr>')
map('n', '<leader>ST', '<cmd>call RestoreSession()<cr>')
map('n', '<leader>gd', '<cmd>Gdiff<cr>')
map('n', '<leader>gb', '<cmd>Gblame<CR>')

vim.api.nvim_exec([[
    function! SaveSessionAndShowGitStatus()
      let session_name = split(getcwd(), "/")[-1]
      execute "silent! mksession! ~/.vim/sessions/" . session_name
      silent tabonly | silent only | Gstatus
    endfunction

    function! RestoreSession()
      let session_name = split(getcwd(), "/")[-1]
      execute "source ~/.vim/sessions/" . session_name
    endfunction
]], true)

opt.diffopt:append({'vertical'})

cmd 'augroup git_stuff'
  -- Clear old autocmds in group
  cmd 'autocmd!'
  cmd 'autocmd FileType gitcommit setl spell'
  cmd 'autocmd FileType gitcommit setl diffopt+=vertical'
  cmd 'autocmd FileType gitcommit nmap <buffer> <S-Tab> <C-p>'
  cmd 'autocmd FileType gitcommit nmap <buffer> <Tab> <C-n>'
  cmd 'autocmd BufRead,BufNewFile */.git/COMMIT_EDITMSG wincmd _'
  cmd 'autocmd BufEnter PULLREQ_EDITMSG setlocal filetype=gitcommit'
cmd 'augroup END'

vim.api.nvim_command('command! GitDiff call GitDiff()')

paq {'lewis6991/gitsigns.nvim'}

require('gitsigns').setup{}

paq {'fatih/vim-go'}

paq {'cohama/lexima.vim'}

--paq {'neovim/nvim-lspconfig'}
--paq {'ojroques/nvim-lspfuzzy'}

--local lsp = require 'lspconfig'
--local lspfuzzy = require 'lspfuzzy'

--lsp.pylsp.setup {}
--lspfuzzy.setup {} -- Make the LSP client use FZF instead of quickfix list
--lsp.tsserver.setup{}


--map('n', '<space>,', '<cmd>lua vim.lsp.diagnostic.goto_prev()<cr>')
--map('n', '<space>;', '<cmd>lua vim.lsp.diagnostic.goto_next()<CR>')
--map('n', '<space>a', '<cmd>lua vim.lsp.buf.code_action()<CR>')
--map('n', '<space>d', '<cmd>lua vim.lsp.buf.definition()<CR>')
--map('n', '<space>f', '<cmd>lua vim.lsp.buf.formatting()<CR>')
--map('n', '<space>h', '<cmd>lua vim.lsp.buf.hover()<CR>')
--map('n', '<space>m', '<cmd>lua vim.lsp.buf.rename()<CR>')
--map('n', '<space>r', '<cmd>lua vim.lsp.buf.references()<CR>')
--map('n', '<space>s', '<cmd>lua vim.lsp.buf.document_symbol()<CR>')

paq {'vim-scripts/matchit.zip'}

paq {'leafo/moonscript-vim'}

paq {'Shougo/neco-vim'}

paq {'kassio/neoterm'}

map('n', '<leader>ro', '<cmd>Topen<cr>', { noremap = true })

paq {'tpope/vim-rails'}

map('n', '<leader>rs', '<cmd>Server<cr>', { noremap = true})
map('n', '<leader>rc', '<cmd>Console<cr>', { noremap = true})

g.rails_projections = {
   ['app/services/*.rb'] =  {
      command = 'service'
}}

paq {'tpope/vim-rake'}

paq {'AndrewRadev/splitjoin.vim', branch = 'main' }

paq {'tpope/vim-surround'}

paq {'nvim-telescope/telescope.nvim'}

map('n', '<C-p>', '<cmd>lua require("telescope.builtin").find_files()<cr>')
map('n', '<leader>f', '<cmd>lua require("telescope.builtin").live_grep()<cr>')
map('n', '<C-x>b', '<cmd>lua require("telescope.builtin").buffers()<cr>')
map('n', 'gs', '<cmd>lua require("telescope.builtin").git_status()<cr>')

paq {'coderifous/textobj-word-column.vim'}

paq {'nvim-treesitter/nvim-treesitter', run = fn[':TSUpdate']}
local ts = require 'nvim-treesitter.configs'
ts.setup {ensure_installed = 'maintained', highlight = {enable = true}}

paq {'tpope/vim-unimpaired'}

paq {'tpope/vim-dispatch'}

map('n', 'd<cr>', ':Dispatch<space>', { noremap = true })
map('n', '<leader>co', '<cmd>Copen<cr>', { noremap = true })
map('n', '<leader>cop', '<cmd>Copen!<cr>', { noremap = true })

paq {'junegunn/vim-peekaboo'}

paq {'tpope/vim-repeat'}

paq {'jremmen/vim-ripgrep'}

-- Allow Ripgrep to work with quick list
vim.api.nvim_command('command! -nargs=* -complete=file Ripgrep :call Rg(<q-args>)>')
vim.api.nvim_command('command! -nargs=* -complete=file Rg :call Rg(<q-args>)')

paq {'tpope/vim-rsi'}

paq {'mg979/vim-visual-multi'}

paq {'xojs/vim-xo', branch = 'main' }

paq {'mattn/webapi-vim'}
