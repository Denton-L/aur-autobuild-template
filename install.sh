#!/bin/bash

set -e

REPO_DIR="$PWD"/repo
AUTO_GPG='gpg --batch --no-tty --yes'

if [ -z "$REPO_NAME" ]
then
	REPO_NAME=local
fi

source settings.conf

sudo pacman -Syu --noconfirm

rm -rf "$REPO_DIR"
git submodule foreach bash -c 'git reset --hard && git clean -xdff'

if [ ! -z "$sign_key" ]
then
	$AUTO_GPG --import package-key.pgp
	$AUTO_GPG --export --output public-package-key.pgp "$sign_key"

	sudo pacman-key --init
	sudo pacman-key -a public-package-key.pgp
	sudo pacman-key --lsign-key "$sign_key"

	SIGNING_ARGS="--sign --key $sign_key"
fi

$AUTO_GPG --recv-keys "${trustedpgpkeys[@]}"
for k in "${trustedpgpkeys[@]}"
do
	$AUTO_GPG --lsign-key "$k" || :
done

mkdir -p "$REPO_DIR"
for p in "${packages[@]}"
do
	pushd "$p"
	makepkg -si $SIGNING_ARGS --noconfirm
	mv *.pkg.tar.xz *.pkg.tar.xz.sig "$REPO_DIR"
	popd
done

repo-add "$REPO_DIR"/"$REPO_NAME".db.tar.xz "$REPO_DIR"/*.pkg.tar.xz
