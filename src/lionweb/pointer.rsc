module lionweb::pointer

alias Id = str;

data Pointer[&T]
  = Pointer(Id uid, str info = "")
  | null(); 
