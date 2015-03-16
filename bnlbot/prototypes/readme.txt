System prerequisites
====================

Subversion
----------
Install Subversion package
    sudo apt-get install subversion

Python
------
Make sure that a Python envionment is present
    python -c "import sys; print(sys.version)"
    ->
    2.7.3 (default, Aug  1 2012, 05:14:39)
    [GCC 4.6.3]

Install python-virtualenv if not in place
    sudo apt-get install python-virtualenv

Install psycopg2 system dependencies
    sudo apt-get install libpq-dev python-dev
    
Create a Python virtual environment
    virtualenv xyz

Activate Python virtual environment
    . ./xyz/bin/activate

Install psycopg2 into virtual environment (latest)
    pip install --ignore-installed psycopg2

Postgresql
----------
Install database
    sudo apt-get install postgresql

vi (.vimrc) settings
--------------------
https://wiki.python.org/moin/Vim
syntax on

http://docs.python-guide.org/en/latest/dev/env/
set textwidth=79  " lines longer than 79 columns will be broken
set shiftwidth=4  " operation >> indents 4 columns; << unindents 4 columns
set tabstop=4     " a hard TAB displays as 4 columns
set expandtab     " insert spaces when hitting TABs
set softtabstop=4 " insert/delete 4 spaces when hitting a TAB/BACKSPACE
set shiftround    " round indent to multiple of 'shiftwidth'
set autoindent    " align the new line indent with the previous line

http://stackoverflow.com/questions/9172802/setting-up-vim-for-python
set smartindent cinwords=if,elif,else,for,while,try,except,finally,def,class

http://stackoverflow.com/questions/18948491/running-python-code-in-vim
nnoremap <buffer> <F9> :exec '!python' shellescape(@%, 1)<cr>
nnoremap <silent> <F5> :!clear;python %<CR>

.vimrc at present time
----------------------
set textwidth=79  " lines longer than 79 columns will be broken
set shiftwidth=4  " operation >> indents 4 columns; << unindents 4 columns
set tabstop=4     " a hard TAB displays as 4 columns
set expandtab     " insert spaces when hitting TABs
set softtabstop=4 " insert/delete 4 spaces when hitting a TAB/BACKSPACE
set shiftround    " round indent to multiple of 'shiftwidth'
set autoindent    " align the new line indent with the previous line
set smartindent cinwords=if,elif,else,for,while,try,except,finally,def,class
syntax on
nnoremap <silent> <F5> :!clear;python %<CR>
