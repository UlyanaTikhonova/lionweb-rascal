module lionweb::pointer

import Type;
import List;
import Node;

alias Id = str;

data Pointer[&T]
    = Pointer(Id uid, str info = "")
    | null(); 

&T <: node resolve(Pointer[&T <: node] pointer, list[node] scope) {
    // Question: why error here?? void is a subtype of node, right?
    //if (pointer == null()) return make(#void, "void", [], ()); 
    list[&T] elements = [];

    Id elemId = pointer.uid;
    for(node scopeNode <- scope)
        visit(scopeNode) {
            case(e: T(uid = elemId)): elements += [e];
        };
    
    if (size(elements) == 0) throw "No element found for the pointer: <pointer>";
    if (size(elements) > 1) throw "More than one element found for the pointer: <pointer>";

    return elements[0];
}

Id getId(&T <: node object) {
    kws = getKeywordParameters(object);
    if ("uid" in kws, Id x := kws["uid"]) {
        return x;
    }
    // return getId(getChildren(typeWithId)[0]);  // injection
    return "no uid found for the object <object>";
} 