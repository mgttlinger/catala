(* This file is part of the Catala compiler, a specification language for tax
   and social benefits computation rules. Copyright (C) 2020 Inria, contributor:
   Emile Rolley <emile.rolley@tuta.io>

   Licensed under the Apache License, Version 2.0 (the "License"); you may not
   use this file except in compliance with the License. You may obtain a copy of
   the License at

   http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
   WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
   License for the specific language governing permissions and limitations under
   the License. *)

open Utils
open Cli

let literal_title = function
  | En -> "Legislative text implementation"
  | Fr -> "Implémentation de texte législatif"
  | Pl -> "Implementacja tekstów legislacyjnych"

let literal_generated_by = function
  | En -> "Document generated by"
  | Fr -> "Document généré par"
  | Pl -> "Dokument wygenerowany przez"

let literal_source_files = function
  | En -> "Source files weaved in this document"
  | Fr -> "Fichiers sources tissés dans ce document"
  | Pl -> "Pliki źródłowe w tym dokumencie"

let literal_disclaimer_and_link = function
  | En ->
      "This document was produced from a set of source files written in the \
       Catala programming language, mixing together the legislative text and \
       the computer code that translates it. For more information about the \
       methodology and how to read the code, please visit \
       \\url{https://catala-lang.org}."
  | Fr ->
      "Ce document a été produit à partir d'un ensemble de fichiers sources \
       écrits dans le langage de programmation Catala, mêlant le texte \
       législatif et le code informatique qui le traduit. Pour plus \
       d'informations sur la méthodologie et sur la façon de lire le code, \
       veuillez consulter le site \\url{https://catala-lang.org}."
  | Pl ->
      "Niniejszy dokument został opracowany na podstawie zestawu plików \
       źródłowych napisanych w języku programowania Catala, łączących tekst \
       legislacyjny z kodem komputerowym, który go tłumaczy. Więcej informacji \
       na temat metodologii i sposobu odczytywania kodu można znaleźć na \
       stronie \\url{https://catala-lang.org}"

let literal_last_modification = function
  | En -> "last modification"
  | Fr -> "dernière modification le"
  | Pl -> "ostatnia modyfikacja"

let get_language_extension = function
  | Fr -> "catala_fr"
  | En -> "catala_en"
  | Pl -> "catala_pl"

let raise_failed_pandoc (command : string) (error_code : int) : 'a =
  Errors.raise_error
    "Weaving failed: pandoc command \"%s\" returned with error code %d" command
    error_code

let run_pandoc (s : string) (backend : Utils.Cli.backend_option) : string =
  let pandoc = "pandoc" in
  let tmp_file_in = Filename.temp_file "catala_pandoc" "in" in
  let tmp_file_out = Filename.temp_file "catala_pandoc" "out" in
  let oc = open_out tmp_file_in in
  Printf.fprintf oc "%s" s;
  close_out oc;
  let pandoc_args =
    [|
      "-f";
      "markdown+multiline_tables";
      "-t";
      (match backend with
      | Cli.Html -> "html"
      | Cli.Latex -> "latex"
      | _ -> failwith "should not happen");
      "-o";
      tmp_file_out;
    |]
  in
  let cmd =
    Format.sprintf "%s %s %s" pandoc
      (String.concat " " (Array.to_list pandoc_args))
      tmp_file_in
  in
  let return_code = Sys.command cmd in
  if return_code <> 0 then raise_failed_pandoc cmd return_code;
  let oc = open_in tmp_file_out in
  let tmp_file_as_string = really_input_string oc (in_channel_length oc) in
  close_in oc;
  tmp_file_as_string
