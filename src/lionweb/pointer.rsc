module lionweb::pointer

alias Id = str;

data Pointer[&T]
  = pointer(Id uid)
  | null(); 

// Question: is realm like a workspace that stores links between ids and nodes?

// T findNode(Pointer[&T] p, Language lang) {

// }