newLisp Docset for Dash
=======================

DocSet for dash

### Build DocSet Manually

#### Requirement

* `newLisp`
* `sqlite3` module (which should be included in newLisp default)
* `newlisp_index.html` and `newlisp_manual.html` which are included in newLisp source tarball

#### Build

`newlisp build-docset.lsp`

#### Alternative Build

This command will only reserve the `Function Alphabet` part and `Appendix` part of the manual file.  
Some descriptions are missing but docset will be 1/3 smaller which can increase the query speed.

`newlisp build-docset.lsp --trim`
