open Rory
open Tyxml

module M = struct
  type t = {
    title : string;
    author : string;
    date : string;
    description : string;
  }
  [@@deriving yaml]
end

module Learning = struct
  include Collection.Make (M)

  let to_html (t : t) =  
    let body = Omd.to_html (body_md t) in
    let doc title body =
      [%html {| 
        <!DOCTYPE html>
        <html lang="en">
          <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>|} (Html.txt title) {|</title>
            <link rel="stylesheet" href="/___blog/css/main.css">
          </head>
          <body>
            |}[ body ]{|
          </body>
        </html>
      |}] [@@ocamlformat "disable"]
    in
    let wrapper =
      [%html "<div class='content'>" [ Html.Unsafe.data body ] "</div>"]
    in
    Tyxml.Html.pp ~indent:true () Format.str_formatter (doc t.meta.title wrapper);
    Format.flush_str_formatter ()
end

module B = Build.Make (Learning)

let () = print_endline (Sys.getcwd ()); B.build ~src_dir:"learning" ~dest_dir:"docs"
