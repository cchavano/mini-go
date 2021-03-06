{  
  open Lexing
  open Parser
  open Printf
  
  exception Error of string

  (* Go keywords table *)
  (* All ident-like tokens are grouped under the same rule, then, thanks to this table, the lexer
     checks if the identifier is a Go keyword or not. It helps reducing the size of
     the generated automata (cf https://www.lri.fr/~conchon/OMED/3/ocamllex.pdf). *)
  let keywords = Hashtbl.create 14

  let () =
    List.iter
      (fun (s, t) -> Hashtbl.add keywords s t) 
      [
        "package", PACKAGE; "import", IMPORT; "func", FUNC; "return", RETURN; "var", VAR;
        "const", CONST; "for", FOR; "if", IF; "else", ELSE; "int", INT; "float64", FLOAT;
        "complex128", COMPLEX; "bool", BOOL; "string", STRING
      ]

  let error msg = raise @@ Error msg

  (* Reference to the last analyzed token *)
  let prev_token = ref (Option.none)

  let tok token = prev_token := Option.some token; token
}

let digit = ['0'-'9']
let letter = ['a'-'z''A'-'Z']
let space = [' ''\t''\r']

let int_lit = (digit (digit | '_')*)* digit
let float_lit = (int_lit '.' int_lit?) | (int_lit? '.' int_lit)
let imag_lit = (int_lit | float_lit) 'i'
let bool_lit = "true" | "false"
let string_lit = '"' [^'"']* '"'

let ident = letter (letter | digit | '_')*

rule read_token = parse
  | "//" [^'\n']* '\n'
  | '\n'
    { 
      (* Semicolons are not mandatory in Go. In short, the lexer automatically inserts a semicolon into the
         token stream after a line's final token if that token could end a statement. More details are given
         in the Go documentation: https://go.dev/ref/spec#Semicolons. *)
      let move lexbuf = new_line lexbuf; read_token lexbuf in
      let add_semi lexbuf = function
        | IDENT _
        | INT | FLOAT | COMPLEX | BOOL | STRING
        | RPAREN | RBRACE
        | INT_LIT _ | FLOAT_LIT _ | IMAG_LIT _ | BOOL_LIT _ | STRING_LIT _
        | RETURN -> new_line lexbuf; tok SEMICOLON
        | _ -> move lexbuf
      in
      match !prev_token with
      | None -> move lexbuf
      | Some v -> add_semi lexbuf v
    }
  | space+  { read_token lexbuf }
  | "/*"    { read_comment lexbuf }
  | '('     { tok LPAREN }
  | ')'     { tok RPAREN }
  | '{'     { tok LBRACE }
  | '}'     { tok RBRACE }
  | ','     { tok COMMA }
  | ';'     { tok SEMICOLON }
  | ":="    { tok DEFINE }
  | "="     { tok ASSIGN }
  | "+"     { tok PLUS }
  | "-"     { tok MINUS }
  | "*"     { tok MULT }
  | "/"     { tok DIV }
  | "<"     { tok LESST }
  | ">"     { tok GREAT }
  | "=="    { tok EQUAL }
  | "!="    { tok NOT_EQUAL }
  | "!"     { tok NOT }
  | "||"    { tok OR }
  | "&&"    { tok AND }
  | int_lit as i
    {
      try
        tok @@ INT_LIT (Int64.of_string i)
      with Failure _ ->
        error (sprintf "int literal '%s' overflows the maximum value of int64" i)   
    }
  | float_lit as f
    {
      try
        tok @@ FLOAT_LIT (float_of_string f)
      with Failure _ ->
        error (sprintf "invalid float literal '%s'" f)
    }
  | imag_lit as im
    {
      try
        let imag_part = String.sub im 0 (String.length im - 1) in
        tok @@ IMAG_LIT (float_of_string imag_part)
      with Failure _ ->
          error (sprintf "invalid imaginary literal '%s'" im)
    }
  | bool_lit as b   { tok @@ BOOL_LIT (bool_of_string b) }
  | string_lit as s
    {
      let forbidden_chars = ['%'; '\\'] in
      List.iter
        (fun c ->
          if String.contains s c then
            error (sprintf "illegal character '%c' in string literal %s" c s)
          else ()) 
        forbidden_chars;
      tok @@ STRING_LIT s
    }
  | ident as id
    {
      try
        tok (Hashtbl.find keywords id)
      with Not_found ->
        tok @@ IDENT (Location.make (lexeme_start_p lexbuf) (lexeme_end_p lexbuf) id)
    }
  | "fmt.Println" as println
    {
      tok @@ PRINTLN (Location.make (lexeme_start_p lexbuf) (lexeme_end_p lexbuf) println)
    }
  | eof { tok EOF }
  | _ as c
    {
      error (sprintf "illegal character '%s'" (String.make 1 c))
    }

and read_comment = parse
  | "*/"  { read_token lexbuf }
  | '\n'  { new_line lexbuf; read_comment lexbuf }
  | eof   { error "unterminated comment" }
  | _     { read_comment lexbuf }