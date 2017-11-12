#!/bin/bash

set -e

source settings.conf

REPO_DIR="$PWD"/repo
AUTO_GPG='gpg --batch --no-tty --yes'

if [ -z "$REPO_NAME" ]
then
	REPO_NAME=local
fi

export GPGKEY="$sign_key"
export MAKEPKG_CONF="$PWD"/makepkg.conf
export PACKAGER="$(git show -s --format='%an <%ae>')"

sudo pacman -Syu --noconfirm

if [ ! -z "$GPGKEY" ]
then
	$AUTO_GPG --import package-key.pgp
	$AUTO_GPG --export --output public-package-key.pgp "$GPGKEY"

	sudo pacman-key --init
	sudo pacman-key -a public-package-key.pgp
	sudo pacman-key --lsign-key "$GPGKEY"

	SIGNING_ARGS="--sign --key $GPGKEY"
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
	makepkg -si $SIGNING_ARGS --noconfirm &> "$REPO_DIR/$p-$(date -u +'%Y-%m-%dT%H:%M:%SZ').log" || :
	popd
done

repo-add -s "$REPO_DIR"/"$REPO_NAME".db.tar.xz "$REPO_DIR"/*.pkg.tar.xz
