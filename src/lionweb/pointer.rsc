module lionweb::pointer

alias Id = str;



data Pointer[&T]
  = pointer(Id uid)
  | null();

