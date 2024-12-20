# Implementation of the LionWeb protocol in Rascal

This project implements LionWeb protocol in the Rascal meta-programming language. 
[LionWeb](https://lionweb.io/) is meant to facilitate the interoperability between various language engineering tools and, in this way, to allow for the reuse of language engineering and modeling tools.

Rascal is a meta-programming language that is used for the implementation of textual DSLs and for more generic use cases of syntax-based analysis and transformation of programming code. 
In Rascal a DSL is defined in the form of a concrete syntax grammar. 
Native to LionWeb models are represented as abstract syntax trees and new types are defined using algebraic data types.
Furthermore, Rascal doesn’t support traditional OO concepts: there are no objects, only immutable values; no user defined sub-typing (inheritance); all models are pure trees, without explicit cross-referencing between their nodes.

This implementation is inspired by and partially reproduces the work from 2017 by Tijs van der Storm on the [conversion between Ecore and Rascal](https://github.com/cwi-swat/rascal-ecore/tree/master).

## Current status

Currently, on the language (M2) level, only one direction, from LionWeb to Rascal, is implemented. 
This is achieved through the following components:
* Lioncore meta-meta-model and LionWeb JSON serialization format are implemented as Rascal algebraic data types (ADTs);
* Translation from JSON to LionCore allows to import a LionWeb language as a LionCore instance (M2);
* Translation from LionCore to Rascal ADT allows to generate the corresponding Rascal structure for the imported language;
* Generation from the LionCore ADT to Rascal textual representation generates the corresponding file with the ADT definitions of the imported language;

On the model (M1) level, both directions, from LionWeb to Rascal and from Rascal to lionWeb, are implemented:
* Translation from JSON to an AST allows to import a LionWeb model (M1) as an instance of the ADT of the previously imported language;
* Translation from a Rascal AST of the previously imported language into a LionWeb JSON model (M1) allows to export this Rascal AST as a LionWeb JSON file;
* The `pointer` and `lionspace` modules provide support for using cross-references in Rascal trees (for the M1 and M2 levels correspondingly).

For the imported LionWeb language we need to create the corresponding concrete syntax using Rascal grammar and the translators between the language ADT and this concrete grammar. 
The example of such a language enhancement can be found in `f1re/lionweb/examples/expression`.

This project was presented at the LangDev 2024 conference. Here is the recording of the talk:

[![IMAGE ALT TEXT HERE](https://img.youtube.com/vi/Uq414dBALg4/0.jpg)](https://www.youtube.com/watch?v=Uq414dBALg4)

## References
* Specification of the [LionWeb serialization format](https://lionweb.io/specification/serialization/serialization.html)
* Specification of the [LionCore meta-meta-model (M3)](https://lionweb.io/specification/metametamodel/metametamodel.html)
* [Rascal meta-programming language](https://www.rascal-mpl.org/)
* An informal introduction into this project in [my blog post](https://www.f1re.io/2024-07-08/lionweb-in-rascal)

