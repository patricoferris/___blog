---
title: Patrick's Corner of the Web
date: 2021-01-01
---

# Patrick Ferris

---

 - At [OCamllabs](https://ocamllabs.io) working on open-source OCaml.
 - Passionate about the environment, accessible technology and ultimately trying to understand more about systems.

## Posts

Slightly more formal and a little longer, be sure to have a look at the extra reading section for a collection of useful resources. [Posts](/posts).

## Site Info

This website is a [MirageOS](https://github.com/mirage/mirage) Unikernel deployed to Google Cloud (using the *virtio* backend, some [Solo5](https://github.com/solo5/solo5) magic and a Github Action for continuous deployment). The [content repo](https://github.com/patricoferris/___blog) uses a really simple [static-site generator](https://github.com/patricoferris/sesame) that I wrote and pushes the built site to the `live` branch. The Unikernel then does a `git pull` using [Irmin](https://github.com/mirage/irmin) from this branch to get the latests content. All of this is possible thanks to: 

 - [@dinosaure's blog](https://github.com/dinosaure/blog.x25519.net) for the Irmin parts.
 - [@sgrove's site](https://github.com/sgrove/riseos) for the Google Cloud deployment idea.

## Software 

[ppx_deriving_yaml](https://github.com/patricoferris/ppx_deriving_yaml) -- an OCaml PPX deriver that can take your OCaml types and make Yaml ones (and back again). 