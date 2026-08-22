#!/bin/bash

set -ex

readonly IS_LIVE_ENV="TRUE"

function bringup_ubuntu() {
	local -r USEFUL_FILES_DIR="${HOME}/my/util/useful-files"
	local -r USEFUL_FILES_CONFIG_DIR="${HOME}/my/util/useful-files/config"
	local -r VIM_COLORS_SOLARIZED_DIR="${HOME}/my/util/vim-colors-solarized"
	local -r VUNDLE_DIR="${HOME}/.vim/bundle/Vundle.vim"
	local -r NVIM_CONFIG_DIR="${HOME}/.config/nvim"

	if [ ! -d "${HOME}/my/util" ] ; then
		mkdir -p ${HOME}/my/util
	fi
	if [ ! -d "${HOME}/.vim/colors" ] ; then
		mkdir -p ${HOME}/.vim/colors
	fi
	if [ ! -d "${NVIM_CONFIG_DIR}" ] ; then
		mkdir -p ${NVIM_CONFIG_DIR}
	fi

	if [ ! -d "${VIM_COLORS_SOLARIZED_DIR}" ] ; then
		git clone https://github.com/altercation/vim-colors-solarized.git ${VIM_COLORS_SOLARIZED_DIR}
	fi
	if [ ! -d "${USEFUL_FILES_DIR}" ] ; then
		git clone https://github.com/pottumuusi/useful-files.git ${USEFUL_FILES_DIR}
	fi
	if [ ! -d "${VUNDLE_DIR}" ] ; then
		git clone https://github.com/VundleVim/Vundle.vim.git ${VUNDLE_DIR}
	fi

	cp ${VIM_COLORS_SOLARIZED_DIR}/colors/solarized.vim ${HOME}/.vim/colors

	sudo apt-get update
	sudo apt-get -y install \
		neovim \
		tmux \
		eatmydata

	cp ${USEFUL_FILES_CONFIG_DIR}/bash/.bash_profile ${HOME}
	cp ${USEFUL_FILES_CONFIG_DIR}/nvim/.config/nvim/init.vim ${NVIM_CONFIG_DIR}/
	cp ${USEFUL_FILES_CONFIG_DIR}/vim/.vimrc ${HOME}
	cp ${USEFUL_FILES_CONFIG_DIR}/x/.Xmodmap ${HOME}
	# cp ${USEFUL_FILES_CONFIG_DIR}/x/.xinitrc ${HOME}
	cp ${USEFUL_FILES_CONFIG_DIR}/tmux/oh_my_tmux/.tmux.conf ${HOME}
	cp ${USEFUL_FILES_CONFIG_DIR}/tmux/oh_my_tmux/.tmux.conf.local ${HOME}

	if [ "TRUE" = "${IS_LIVE_ENV}" ] ; then
		if [ -z "$(grep "Storage=volatile" /etc/systemd/journald.conf)" ] ; then
			echo 'Storage=volatile'  | sudo tee -a /etc/systemd/journald.conf > /dev/null
		fi
		if [ -z "$(grep "RuntimeMaxUse=30M" /etc/systemd/journald.conf)" ] ; then
			echo 'RuntimeMaxUse=30M' | sudo tee -a /etc/systemd/journald.conf > /dev/null
		fi
	fi

	source ${USEFUL_FILES_DIR}/src/git/aliases.sh

	echo "Run to remove libreoffice:"
	echo "sudo apt-get remove --purge libreoffice* && sudo apt-get clean && sudo apt-get autoremove"
}

function main() {
	if [ -n "$(lsb_release -a | grep "Ubuntu")" ] ; then
		bringup_ubuntu
	fi
}

main
