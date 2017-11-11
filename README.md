# aur-autobuild-template

A template for automating your Arch AUR builds using Travis CI. By the way, I use Arch.

Feel free to fork this template and use it for your own builds. Contributions are also welcome!

## Dependencies

* [ruby-travis](https://aur.archlinux.org/packages/ruby-travis/)
* [docker](https://www.archlinux.org/packages/community/x86_64/docker/)
    * Optional for local testing.

## Setup

### Local Repository

First, you will need to get a list of all foreign packages. This list should be ordered with any
dependencies coming before packages that depend on them. The following snippet will automate that
for you:

```bash
for p in $(pacman -Qmq)
do
    pactree -ur $p
done | tac | awk '!x[$0]++' | tac | grep -Fxvf <(pacman -Qnq)
```

In `settings.conf`, the `packages` array should be populated with this list.

Next, you must create the git submodules. If all of your foreign packages were installed from the
AUR, the following script will clone all the submodules:

```bash
for p in $(pacman -Qmq)
do
    git submodule add --branch master https://aur.archlinux.org/$p.git
done
```

At this point, you should review all PKGBUILDs that have been cloned since there may be new commits
since the last time your AUR packages were updated.

If you trust all the PKGBUILDs and the `validpgpkeys` in each PKGBUILD, you'll have to add each key
to `settings.conf` in the `trustedpgpkeys` array.

A simple way of getting all PGP keys is this:

```bash
git submodule foreach --quiet bash -c 'source PKGBUILD &&
if [ ! -z "${validpgpkeys[0]}" ]
then
    printf "%s\n" "${validpgpkeys[@]}"
fi' | sort -u
```

### Travis CI

First, push your repository to GitHub. Next, navigate to https://travis-ci.org/profile and turn on
the switch corresponding to the repository you just pushed.

Next, you'll need to generate a GitHub access token in order to release packages. Go to
https://github.com/settings/tokens and `Generate new token`. Check the `repo.public_repo` scope.
Encrypt this token by running `travis encrypt GITHUB_TOKEN=<token>`, then add the line printed into
`env.global` of `.travis.yml`.

Finally, if you would like, you may configure any of the other variables in the `env` section.

You may now push your changes to GitHub. This should automatically trigger a Travis CI build which,
when complete, will push a release to
`https://github.com/<user>/<repository>/releases/tag/$REPO_NAME`, where `$REPO_NAME` is the value of
`env.global.REPO_NAME` in `.travis.yml`.

### Pacman

In `/etc/pacman.conf`, add the following section:

```
[$REPO_NAME]
Server = $URL
```

Where `$REPO_NAME` should be replaced the value of `env.global.REPO_NAME` in `.travis.yml` and
`$URL` should be replaced with the URL mentioned in the section above.

If you do not plan on signing your packages, add `SigLevel = PackageOptional` as well.

### Signing your Packages (Optional but Highly Recommended!)

Create a new PGP key using `gpg --gen-key`; follow the instructions given to create your key. Even
though it is against normal best practices, you should use *no password* for your key because there
is no security gained if you have to tell Travis CI your password anyway. Make sure to keep a copy
of the revocation certificate in case your key becomes compromised. Also, make note of your key's
fingerprint for the following steps.

In `settings.conf`, add your key's fingerprint to `sign_key`.

You'll also have to export your key for `pacman-key` so that it can sign it. This tells pacman to
trust the key you've just created. Run the following to do that:

```bash
gpg --export --output public-package-key.pgp <fingerprint>
sudo pacman-key -a public-package-key.pgp
sudo pacman-key --lsign-key <fingerprint>
```

Finally, you'll have to send the encrypted private key to Travis CI. Export your private key by
running `gpg --export-secret-keys --output package-key.pgp <fingerprint>`.
Next, encrypt your private key for Travis by running
`travis encrypt-file package-key.pgp` and adding the output line to your
`.travis.yml` as the first line under `before_install`.

**Warning!** Make sure that you do not accidentally commit your private key. That would be very,
very bad.

### Finishing

That's it, you're done! In order to use the newly created packages, simply run `sudo pacman -Syyu`
to update the package databases (and also, your packages because Arch doesn't support partial
upgrades). Finally, you can install all of your AUR packaages using a simple
`sudo pacman -S <packages>`.

## Contributing

Pull-requests and suggestions are welcome! Please let me know if you have any suggestions or
improvements!

## Acknowledgements

Credit to [/u/_ahrs](https://www.reddit.com/r/linuxmasterrace/comments/7aai76/i_am_using_archlinux/dp94r3s/) for the inspiration!
