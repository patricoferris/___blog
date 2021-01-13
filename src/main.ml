open Sesame

(* Meta Descriptions *)
module Post = struct
  type reading = { name : string; description : string; url : string }
  [@@deriving yaml]

  type t = {
    title : string;
    description : string;
    date : string;
    authors : string list;
    topics : string list;
    reading : reading list;
  }
  [@@deriving yaml]
end

module Page = struct
  type t = { title : string; date : string } [@@deriving yaml]
end

(* Resuable components *)
module Comps = struct
  open Tyxml

  let content c = [%html "<div class='content'>" c "</div>"]

  let title t = [%html "<h1 class='h1-title'>" [ Tyxml.Html.txt t ] "</h1>"]

  let date p = [%html "<p class='date'>" [ Html.txt p ] "</p>"]

  let navbar =
    [%html
      "<div class='nav'><a class='title' href='/'>home</a><a class='title' \
       href='https://twitter.com/patricoferris'>@patricoferris</a><a href='#' \
       id='toggle' class='title'>toggle dark</a></div>"]

  let reading lst =
    let mk_text t = [ Html.txt t ] in
    let mk_item (title, description, url) =
      [%html
        "<li><p><a href='" url "'>" (mk_text title) "</a> -- "
          (mk_text description) "</p></li>"]
    in
    let ol_list = List.map mk_item lst in
    [%html "<ul>" ol_list "</ul>"]

  let html ?(lang = "en") ?(css = "/main.css") ~title ~description ~body =
  [%html {| 
    <!DOCTYPE html>
    <html lang='|} lang {|'>
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <script defer="defer" src="/main.js"></script> 
      <meta name="description" content="|}
      description
      {|"> 
      <link rel="stylesheet" href="|} css {|">
      <title>|} (Html.txt title) {|</title>
    </head>
    <body>
      <script src="/root.js"></script> 
      |} body {|
    </body>
    </html>
  |}] [@@ocamlformat "disable"]
end

(* Collections *)
module PostCollection = struct
  include Collection.Make (Post)

  let to_html (t : t) =
    let open Tyxml in
    let toc = Transformer.Toc.toc (body_md t) in
    let html_toc = Transformer.Toc.to_html toc in
    let align_center c =
      [%html "<div style='text-align: center;'>" c "</div>"]
    in
    let r =
      t.meta.reading
      |> List.map (fun (r : Post.reading) -> (r.name, r.description, r.url))
    in
    let body =
      [
        Tyxml.Html.div
          [
            Comps.navbar;
            Comps.content
            @@ [
                 align_center
                 @@ [
                      Comps.title t.meta.title;
                      Comps.date t.meta.date;
                      Tyxml.(Html.p [ Html.em [ Html.txt t.meta.description ] ]);
                      Tyxml.Html.br ();
                      Tyxml.Html.hr ();
                      Tyxml.Html.br ();
                    ];
                 html_toc;
                 Tyxml.Html.Unsafe.data
                   (body_md t |> Transformer.Toc.transform |> Omd.to_html);
                 Comps.reading r;
               ];
          ];
      ]
    in
    Comps.html ~lang:"en" ~css:"/main.css" ~title:t.meta.title
      ~description:t.meta.description ~body

  let index_html ts =
    let open Tyxml in
    let ts =
      List.map
        (fun t ->
          let path = Filename.chop_extension t.path ^ ".html" in
          [%html
            "<li><p><a href=" ("/" ^ path) ">"
              [ Html.txt t.meta.title; Html.txt " -- "; Html.txt t.meta.date ]
              "</a></p><p>"
              [ Html.em [ Html.txt t.meta.description ] ]
              "</p></li>"])
        ts
    in
    let body =
      [
        Comps.navbar; Comps.content [ [%html "<ul class='index'>" ts "</ul>"] ];
      ]
    in
    Comps.html ~lang:"en" ~css:"/main.css" ~title:"Main"
      ~description:"home page" ~body
end

module PageCollection = struct
  include Collection.Make (Page)

  let to_html (t : t) =
    let body =
      [
        Tyxml.Html.div
          [
            Comps.navbar;
            Comps.content
            @@ [ Tyxml.Html.Unsafe.data (body_md t |> Omd.to_html) ];
            Tyxml.Html.(p [ em [ txt ("Last built: " ^ Utils.get_time ()) ] ]);
          ];
      ]
    in
    Comps.html ~lang:"en" ~css:"/main.css" ~title:t.meta.title
      ~description:"home page" ~body
end

(* Builders *)
module PostBuilder = Build.Make (PostCollection)
module PageBuilder = Build.Make (PageCollection)

(* ========= Build Script =========== *)

let handle_errors = function Ok t -> t | Error (`Msg m) -> failwith m

let cp a b =
  let cmd = Bos.Cmd.(v "cp" % a % b) in
  Bos.OS.Cmd.run cmd |> handle_errors

let copy_svgs () =
  let svgs =
    Files.all_files "posts"
    |> List.filter (fun f ->
           try Filename.extension f = ".svg" with Invalid_argument _ -> false)
  in
  List.iter
    (fun f ->
      print_endline f;
      Files.output_file ~path:("public/" ^ f)
        ~content:(Files.read_file f |> handle_errors)
      |> handle_errors)
    svgs

let check_and_copy_styles f =
  match Bos.OS.File.read f with
  | Ok content -> (
      (try Css.Parser.parse_stylesheet content
       with Css.Lexer.ParseError _ -> failwith "Broken CSS!")
      |> ignore;
      Files.output_file ~path:"public/main.css" ~content |> function
      | Ok _ -> ()
      | Error (`Msg m) -> failwith m)
  | Error (`Msg m) -> failwith m

let () =
  let list_files dir =
    Files.all_files dir |> List.filter (fun f -> Filename.extension f = ".md")
  in
  PostBuilder.build_html ~list_files ~src_dir:"posts" ~dest_dir:"public" ()
  |> PostCollection.index_html
  |> fun doc ->
  Files.output_html ~path:"public/posts/index.html" ~doc |> handle_errors;
  let _index =
    PageBuilder.build_single ~path:"index.md" ~out:"public/index.html"
  in
  check_and_copy_styles (Fpath.v "main.css");
  cp "_build/default/src/js/main.bc.js" "public/main.js";
  cp "_build/default/src/js/root.bc.js" "public/root.js";
  copy_svgs ()
