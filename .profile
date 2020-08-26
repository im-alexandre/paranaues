# ~/.profile: executed by the command interpreter for login shells.
# This file is not read by bash(1), if ~/.bash_profile or ~/.bash_login
# exists.
# see /usr/share/doc/bash/examples/startup-files for examples.
# the files are located in the bash-doc package.

# the default umask is set in /etc/profile; for setting the umask
# for ssh logins, install and configure the libpam-umask package.
#umask 022

# if running bash
#if [ -n "$BASH_VERSION" ]; then
    ## include .bashrc if it exists
    #if [ -f "$HOME/.bashrc" ]; then
	#. "$HOME/.bashrc"
    #fi
#fi

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/bin" ] ; then
    PATH="$HOME/bin:$PATH"
fi

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/.local/bin" ] ; then
    PATH="$HOME/.local/bin:$PATH"
fi

#Variáveis JAVA
JAVA_HOME=/opt/java
CLASSPATH=$JAVA_HOME/lib:.
PATH=$PATH:$JAVA_HOME/bin
export JAVA_HOME
export CLASSPATH
export PATH

export LD_LIBRARY_PATH=/opt/instantclient_12_2:
export BIN=/home/alexandre/.bin
export PATH=$BIN:$PATH
export GTK_IM_MODULE=cedilla
export QT_IM_MODULE=cedilla
export VIM_APP_DIR=/usr
export ECLIM_HOME=/home/alexandre/.eclipse/eclipse/
export PATH=$PATH:$ECLIM_HOME
