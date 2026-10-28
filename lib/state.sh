#!/bin/sh

LC_ALL=C
export LC_ALL

: "${SW_LIB:=}"
: "${SW_PROG:=shiwake}"
: "${SW_WIDTH:=80}"
: "${SW_DIR:=}"
: "${SW_DRY_RUN:=no}"
: "${SW_BATCH:=${SHIWAKE_BATCH:-512}}"
: "${SW_ARGS_DONE:=no}"
: "${SW_BUCKETS:=#:[!A-Za-z] A:[Aa] B:[Bb] C:[Cc] D:[Dd] E:[Ee] F:[Ff] G:[Gg] H:[Hh] I:[Ii] J:[Jj] K:[Kk] L:[Ll] M:[Mm] N:[Nn] O:[Oo] P:[Pp] Q:[Qq] R:[Rr] S:[Ss] T:[Tt] U:[Uu] V:[Vv] W:[Ww] X:[Xx] Y:[Yy] Z:[Zz]}"
: "${SW_FOUND:=0}"
: "${SW_FOLDERS:=0}"
: "${SW_MOVED:=0}"
: "${SW_KEPT:=0}"
: "${SW_FAILED:=0}"
: "${SW_FILLED:=0}"
: "${SW_OS:=}"
: "${SW_LAST_FOUND:=}"
: "${SW_LAST_FILLED:=}"
: "${SW_LAST_BLOCKED:=}"
