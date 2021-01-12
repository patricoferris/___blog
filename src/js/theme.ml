open Brr
open Brr_io

let str = Jstr.of_string

module Css = struct
  let css lst r =
    List.iter
      (fun (k, value) -> El.(set_inline_style (str k) (str value) r))
      lst

  let off_white = "#fffff7"

  let set_dark =
    css
      [
        ("--invert", "1");
        ("--background-color", "#121212");
        ("--font-color", off_white);
        ("--accent-color", "orange");
      ]

  let set_light =
    css
      [
        ("--invert", "0");
        ("--font-color", "#121212");
        ("--background-color", off_white);
        ("--accent-color", "deeppink");
      ]
end

module Store = struct
  let str = Jstr.of_string

  let storage () = Storage.local G.window

  let set s x y = Storage.set_item s (str x) (str y)

  let get s x = Storage.get_item s (str x)

  let handle default = function
    | Ok t -> t
    | Error m ->
        Console.(warn [ str "Encountered an error"; Jv.Error.name m ]);
        default
end
