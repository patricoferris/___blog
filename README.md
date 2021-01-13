# Blog

A personal site.

## Install and Develop

```bash
# Server of your choice 
opam install cohttp-lwt-unix

# Dependency install
opam pin add -yn pf-blog.dev './'
opam depext -yt pf-blog.dev
opam install -t -y . --deps-only

# Javascipt and SSG Building
dune build --profile release
_build/default/src/main.exe

# Localhosting
cohttp-server-lwt ./public
```