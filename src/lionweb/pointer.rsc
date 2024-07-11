module lionweb::pointer

import IO;
import Type;
import List;
import Node;

alias Id = str;

data Pointer[&T]
    = Pointer(Id uid, str info = "")
    | null(); 

// `&T <: node` as a return type results in the CallFailed exception, as we actually return a node value.
node resolve(Pointer[&T <: node] pointer, list[node] scope) {
    assert pointer != null(): "cannot resolve null";

    list[node] elements = [];

    // The visit with `case &T <: node` doesn't work: it doesn't visit our &T nodes at all
    // But now we visit all elements is a tree
    visit(scope) {
        case node elem: {
            if(getId(elem) == pointer.uid) {
                elements += [elem];
            }
        }
    };
    
    if (size(elements) == 0) throw "No element found for the pointer: <pointer>";
    if (size(elements) > 1) throw "More than one element found for the pointer: <pointer>";

    return elements[0];
}

// An alternative way to find the referenced element: via inline visit `\`
// &T <: node lookup(node root, Id elemId) = aNode
//   when /&T<:node aNode := root, getId(aNode) == elemId;

Id getId(node object) {
    kws = getKeywordParameters(object);
    if ("uid" in kws, Id x := kws["uid"]) {
        return x;
    }
    
    // getKeywordParameters doesn't fetch 'delegated' keyword parameters (wrapped inheritance), 
    // so we look for the uid in the children of this node:
    if (size(getChildren(object)) > 0)    
        return getId(getChildren(object)[0]);
    
    // Otherwise there is no uid in this object
    throw "No uid field found for the object: <object>";
    // return "no-uid";
} 