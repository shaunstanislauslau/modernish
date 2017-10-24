#! /shell/bug/test/for/moderni/sh
# -*- mode: sh; -*-
# See the file LICENSE in the main modernish directory for the licence.

# BUG_PP_08: When IFS is null, unquoted $@ and $* do not generate one field
# for each positional parameter as expected, but instead join them into a
# single field.
# Found on: yash < 2.44

set "abc" "def ghi" "jkl"
push IFS
IFS=
set $@
pop IFS
case $#,${1-},${2-},${3-} in
( "3,abc,def ghi,jkl" ) return 1 ;;
( "1,abcdef ghijkl,," ) ;;	# got bug
( "1,abc def ghi jkl,," ) ;;	# got bug (pdksh, FTL_PARONEARG)
( * ) echo 'BUG_PP_08.t: internal error: undiscovered bug with unqoted $@'; return 2 ;;
esac
