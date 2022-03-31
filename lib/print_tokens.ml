open Lexer
open Printf

let token_to_string = function
  | PACKAGE -> "PACKAGE"
  | IMPORT -> "IMPORT"
  | FUNC -> "FUNC"
  | VAR -> "VAR"
  | CONST -> "CONST"
  | FOR -> "FOR"
  | IF -> "IF"
  | ELSE -> "ELSE"
  | RETURN -> "RETURN"
  | INT -> "INT"
  | FLOAT -> "FLOAT"
  | COMPLEX -> "COMPLEX"
  | BOOL -> "BOOL"
  | STRING -> "STRING"
  | ASSIGN -> "ASSIGN"
  | DCL_ASSIGN -> "DCL_ASSIGN"
  | PLUS -> "PLUS"
  | MINUS -> "MINUS"
  | MULT -> "MULT"
  | DIV -> "DIV"
  | LESST -> "LESST"
  | GREAT -> "GREAT"
  | EQUAL -> "EQUAL"
  | NOT_EQUAL -> "NOT_EQUAL"
  | AND -> "AND"
  | OR -> "OR"
  | NOT -> "NOT"
  | LPAREN -> "LPAREN"
  | RPAREN -> "RPAREN"
  | LBRACE -> "LBRACE"
  | RBRACE -> "RBRACE"
  | COLON -> "COLON"
  | COMMA -> "COMMA"
  | SEMICOLON -> "SEMICOLON"
  | PRINTLN -> "PRINTLN"
  | INT_LIT i -> sprintf "INT_LIT '%Li'" i
  | FLOAT_LIT f -> sprintf "FLOAT_LIT '%f'" f
  | IMAG_LIT im -> sprintf "IMAG_LIT '%f'" im
  | BOOL_LIT b -> sprintf "BOOL_LIT '%b'" b
  | STRING_LIT s -> sprintf "STRING_LIT '%s'" s
  | IDENT id -> sprintf "IDENT '%s'" id
  | EOF -> "EOF"

let print_tokens lexbuf =
  let rec get_tokens acc lexbuf =
    let token = read_token lexbuf in
    match token with
    | EOF -> acc ^ "EOF"
    | _ ->
      let acc' = sprintf "%s%s\n" acc (token_to_string token) in
      get_tokens acc' lexbuf
  in
printf "%s\n" (get_tokens "" lexbuf)