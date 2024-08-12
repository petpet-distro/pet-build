#!/bin/sh

set -e; # exit on error

shitdir="$(pwd)/build";
builddir="$shitdir/build";
pkgdir="$shitdir/pkgs"
bundledir="$shitdir/bundle";
fetchdir="$shitdir/fetch"

mkdir -p "$shitdir";
mkdir -p "$builddir";
mkdir -p "$pkgdir";
mkdir -p "$bundledir";
mkdir -p "$fetchdir";

cmdExists()
{
	command -v $1 2>&1 1>/dev/null

	if [ "$?" = "0" ]; then
		printf "y";
	else
		printf "n";
	fi
}

. ./PETBUILD

printf "Building %s v%s-r%s\n" "$pkgname" "$pkgver" "$pkgrel";

cd "$fetchdir";
curl -L "$pkgtb" > "ugh.tar";
tar xvf "ugh.tar";
cd "$pkgname-$pkgver";
cp -r * "$builddir/";

cd "$builddir";
if [ "$(cmdExists "configure")" = "y" ]; then
	configure;
fi

build
package

for subpkgname in $subpkgs; do
	j="package_$(printf "%s\n" "$subpkgname" | sed "s/-/_/g")"

	mkdir -p "$pkgdir/$subpkgname"
	cd "$pkgdir/$subpkgname"

	export packagedir="$subpkgdir/$subpkgname"

	petcp()
	{
		k="${1%/*}";

		mkdir -p "$pkgdir/$subpkgname/$k"
		cp -rv "$bundledir/$1" "$pkgdir/$subpkgname/$k"
	}

	"$j";

	tar cpf - * | xz -vvve9 -T1 > "$pkgdir/$subpkgname.tar.xz";
done

