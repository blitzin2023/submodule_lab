#!/bin/sh

# compare历史文件与当前文件（一般用于git commit之前的精细化处理）
function git-diff-file-with-history () {
    local FILE=$1
    local commitId=$2
    local diff_cmd="$3"
    if [ ! -f "$FILE" ]; then
        echo "need : File [Commit-ID, HEAD] [Compare-CMD, vimdiff]"
        return 2
    fi
    local commitId_defalut="HEAD"
    if [ -z "$commitId" ]; then
        commitId=$commitId_defalut
    fi

    local diff_cmd_defalut="vimdiff "
    if [ -z "$diff_cmd" ]; then
        diff_cmd=$diff_cmd_defalut
    fi

    local gitROOT=`git rev-parse --show-toplevel 2>/dev/null`
    if [ -z "$gitROOT"  ]; then
        echo "not in git repo."
        return 2
    fi
    git-log-is-commit-ok $commitId || return 1

    local refFile=.`basename ${FILE}`.v${commitId}
    local f=`git-path-get-file-relatively-path-in-git-root $FILE`
    git show ${commitId}:$f > $refFile || return 1
    local tmpfile=`tmp-gen-safe-file`
    cat > $tmpfile <<EOF
    $diff_cmd  $refFile  $FILE
    rm $refFile
EOF

    source $tmpfile
    rm $tmpfile
}
function git-compare-file-with-history () {
    git-diff-file-with-history
}
