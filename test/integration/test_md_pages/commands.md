<!-- ============================================================ -->
## COMMANDS

### Without arguments

\newcommand{\foo}{bar}

Command `\foo`: \foo;

### With arguments

\newcommand{\fooz}[1]{bar:#1}

Command `\fooz{abc!}`: \fooz{abc!}.

### Nesting

\newcommand{\bar}[1]{bar>#1<}
\newcommand{\foo}[1]{foo:\bar{#1}}

Command `\foo{abc}`: \foo{abc}

<!-- ============================================================ -->
## ENVIRONMENTS
**TODO**
