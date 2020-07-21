---
authors:
  - Patrick Ferris
title: Well Typed Stack
updated: July 20, 2020 6:11 PM
tags:
  - mirage
  - irmin
  - apollo
  - reason
  - ocaml
---
From my not-so-distant days of undergraduate computer science, a well-typed term in a programming language is one that we can assign some type `T` to in our typing relation. So we might give `0` the type `Nat` and `0` becomes well-typed. Functions like `succ t` are typed as `Nat` so long as `t` is a `Nat`. 

The **Well Typed Stack** is a little less formal... and by that I really mean trying to write all parts of the web stack using a statically typed programming language like OCaml. This post is a short introduction to **Rory** - a well-typed stack. 

## Server

The server handles fetching and modifying data, serving up static file content like `index.html` or `main.css`, it also acts as an OAuth server (see content management later in the post).

### MirageOS 

Rory uses MirageOS as deployment target. This means the web application (client code) is wrapped up in a Unikernel to reduce its [carbon footprint](https://mirage.io/blog/ccc-2019-leipzig) and hopefully make it more [secure](https://indico.cern.ch/event/800623/attachments/1799061/3022475/cern-20190510-mehnert-mirageos.pdf). 

### Irmin

At its core, Rory is very similar to [Canopy](https://github.com/Engil/Canopy) in that it uses Git-based stores for holding and modifying data. To do this in OCaml it uses [Irmin](https://irmin.io/) to create an in-memory data-store that is syncable and modifiable. What's more, Irmin comes with some useful tools to expose that data via a Graphql endpoint.

For now it pulls the blog content to a `trunk` branch and exposes the modified data to the `data` branch. Unfortunately, [due to an ocaml-git issue](https://github.com/mirage/ocaml-git/issues/364) syncing doesn't quite work yet. In the meantime the live site pins [this version](https://github.com/patricoferris/irmin/tree/mirage-site) of ocaml-git to always pull everything to a fresh repo. 

### Graphql

As mentioned, data for the client is exposed with a Graphql endpoint. Using the Irmin CLI tool from the blog repository a Graphql schema can be generated.

```bash
$ irmin graphql --port 8080
$ npx get-graphql-schema http://localhost:8080/graphql -j > graphql_schema.json 
```

## Client

### ReasonReact

[ReasonML](https://reasonml.github.io/) is a bridge connecting the Javascript and OCaml ecosystems. We get the safety guarantees of static typing and easier interoperability with JS. [ReasonReact](https://reasonml.github.io/reason-react/en/) is a library for giving you the benefits of the ReactJS framework with... types! 

### Apollo-Graphql

[Apollo-Graphql](https://www.apollographql.com/) is a platform for building Graphql-based web apps - Rory uses the Apollo Client to wrap components and the [React hooks](https://github.com/reasonml-community/reason-apollo-hooks) to fetch data in a smart way with out-of-the-box caching. 

Fetching data can be "type checked" using the schema and the [graphql-ppx](https://github.com/reasonml-community/graphql-ppx) - the blog page for example asks for: 

```ocaml
module UserQuery = [%graphql {|
  query UserQuery {
    branch(name: "trunk") {
      tree {
        get_tree(key: "blogs") {
          list_contents_recursively {
            key
          }
        }
      }
    }
  }
|}];
```

## Content Management 

The blog content is of course stored as a git repository on Github. To make it easier to write, draft and publish blog posts Rory uses [NetlifyCMS](https://www.netlifycms.org/) to... content manage. On top of this, a nifty Github Action in the blog repo set to fire on a push event will hit the sync endpoint of Rory and causes the data to reload without a rebuild!

Rory is still very much a work-in-progress but you can check it out here: *coming soon*
