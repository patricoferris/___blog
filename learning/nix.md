---
title: Nix Package Manager 
description: Some notes about the Nix Package man
date: 2020-10-01 11:06:23
author: Patrick Ferris
---

# Nix Overview 

Notes on [Nix](https://nixos.org/) -- a package manager for Linux and Unix-like systems.

## Principles 

 The main goals of nix are: 

 - **Safety**: which encompasses easy specification of package dependencies and support for multiple variants or versions of a package
 - **Reliability**: downloading or upgrading a package shouldn't break other packages and neither should the system be left in some transient state between versions or upgrades. 
 - **Reproducibility**: if it works on one machine it should work on another machine which requires good package isolation.

## A Functional Model of Package Management 

 Nix acts in a functional way. Packages are treated as first-class citizens much like functions in a functional programming language. The actions applied to packages are also functional in that they have no side-effects. 

 What this provides is a simpler and easier to reason about model for package management. Similarly without this idea of mutability implementing the rollback mechanisms for Nix is simple. 

 ### Nix Store 

 The nix store contains the packages (usually located at `/nix/store`). The actual directory for a package is unique as it is identified by a hash of the build dependency graph of that package. This is where the afore mentioned immutability comes from.

> Nix Store operations are atomic

 Consider updating a package -- Nix doesn't destructively touch a package which currently works and is being depended on by another package.

 Uninstalling a package doesn't delete it -- to do that you have to run the Nix garbage collector. 

 ### Package-specific Vs. Global Locations 

 Nix stores dependencies in a package-specific way not globally (like opam's default global switches). A direct-consequence of this is that the chances for missing dependencies is greatly reduced. Anecdotally, I have pushed an OCaml project to Github many times forgetting to update the package list because I already had it globally installed. CI thankfully catches this, but Nix's model means it would be likely caught before!


## Source Vs. Binary 

The "safest" (but most tedious for development) approach to building packages is to build from source. Download the code of the package along with its dependencies (including things like the C compiler!) and build from there. This takes a long time... 

Usually, a central, accessible cache is uses to deploy pre-built binaries. Thanks to Nix's hashing scheme, packages that are about to be built can have their hashes checked to the [Nix cache](http://cache.nixos.org/) to see if it already exists. If nothing is found, then build from source. 

## Nix Expressions

Nix expressions are the functional language that is used to build packages -- describing dependencies, sources, build scripts, environment variables etc. There is a strong emphasis that these should be as **deterministic** as possible. 

Example paraphrased and taken from [here](https://nixos.org/manual/nix/stable/#sec-expression-syntax): 

```nix
{ stdenv, fetchurl, perl }: 1

stdenv.mkDerivation { 2
  name = "hello-2.1.1"; 3
  builder = ./builder.sh; 4
  src = fetchurl { 5
    url = ftp://ftp.nluug.nl/pub/gnu/hello/hello-2.1.1.tar.gz;
    sha256 = "1md7jsfd8pa45z73bz1kszpp01yw6x5ljkjk2hx7wl800any6465";
  };
  inherit perl; 6
}
```

1. This is a function which accepts three arguments in order to build this package. 
2. Building stuff from other stuff equals a *derivation*.
3. Used for human-readability
4. The build step -- will default to `configure; make; make install`
5. The source of the package is bound to the result of fetching -- this takes a location `url` and the expected hash of the contents of the file.
6. Lastly, the package needs perl so we bind perl to perl using inherit.

The build script looks like: 

```sh
source $stdenv/setup 1

PATH=$perl/bin:$PATH 2

tar xvfz $src 3
cd hello-*
./configure --prefix=$out 4
make
make install
```

1. At the beginning of a Nix build everything is removed i.e. `PATH` is nothing so you don't accidentally use the system-wide C compiler. 
2. `$perl` points to the Perl packages in Nix. 
3. Unpacking the src -- everything happens in a fresh directory inside `/tmp` 
4. The `$out` parameter gets the Nix-specific hash directory for the packages i.e. `/nix/store/<hash>-package.1.2.0` 

# Details 

## Security 

The typical approach to this is all package management operations must be perform by `root` in a single-user model. Nix supports this. But it also supports a multi-user model.

In the multi-user model, `root` can perform the actions of a predefined list of allowed users ensuring they can't: 

 - Install malicious software or interfere with packages used by other users 
 - **Use a pre-built binary cache to install packages**

This achieved by running the `nix-daemon` waiting for built commands from users. 

## Channels 

An important aspect to package management is keeping up to date with the latest changes and versions. Downloading the latest nix expressions for packages and upgrading the store through `nix-env` is a little tedious. Channels allow you to subscribe for new updates. 

To me, channels feel a lot like opam repositories. Note the similarities is adding and updating channels to repos. 

```
$ nix-channel --add https://nixos.org/channels/nixpkgs-unstable
$ nix-channel --update 
$ opam repo add shakti https://github.com/patricoferris/opam-cross-shakti.git 
$ opam update 
```

Nix also comes with [http, aws and ssh](https://nixos.org/manual/nix/stable/#sec-sharing-packages) mechanisms to share stores across machines.

# opam2nix 

[Opam2nix](https://github.com/timbertson/opam2nix) allows a user to generate Nix Expressions from opam packages -- it acts as a transformation from package manager to package manager. Note it is not available from the nix repository (`nixpkgs`) so a manual install is necessary.  

The first step is to generate the `default.nix` package from your `package.opam` file. This will use the latest opam central repository. Then, using `nix-build` or `nix-shell` you can build the package and start using it. 