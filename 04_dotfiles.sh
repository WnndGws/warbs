#!/bin/env zsh
## Using zsh since that us my user shell, but also so we can use bash-isms

printf 'GPG and SSH should not be set up. If it isnt, quit this and set them up or wont be able to clone the git repos'

while true; do
    read -p "Are the GPG and SSH keys added to github" yn
    case $yn in
        [Yy]* ) break;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
    esac
done

mkdir ~/git && cd ~/git
git clone git@github.com:wnndgws/dotfiles.git
git clone git@github.com:wnndgws/scripts.git

cd ~/git/dotfiles
for i in */; do
    stow --restow --target=~ $i
done
zsh
