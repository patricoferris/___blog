(lang dune 2.7)

(generate_opam_files true)

(source
 (github patricoferris/patricoferris.com))

(authors "pf341@patricoferris.com")

(maintainers "pf341@patricoferris.com")

(package
 (name pf-blog)
 (synopsis "Patrick Ferris' blog")
 (depends
  js_of_ocaml
  brr
  (tyxml-ppx
   (>= 4.4.0))
  (tyxml
   (>= 4.4.0))
  (sesame
   (>= ~dev))
  (ppx_deriving_yaml
   (>= 0.1.0))
  (css-parser
   (>= 0.2.4))
  (bos
   (>= 0.2.0))))
