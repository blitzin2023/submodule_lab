#!/bin/sh

# 都是一些修改 git 提交中的邮箱信息的函数

# 在所有提交中替换提交者
function git-commit-change-info-all () {
    # 老邮箱
    local OLD_EM=$1
    local CC=\'
    # 新名字
    local NEW_NM=$2
    # 新邮箱
    local NEW_EM=$3
    if [ $# -lt 3 ]; then
		echo ww
        return
    fi
	local here=`pwd`
	git-root
    local TMP_FILE=/tmp/reset_email_all
(
cat <<EOF
git filter-branch --env-filter ${CC}

OLD_EMAIL="$OLD_EM"
CORRECT_NAME="${NEW_NM}"
CORRECT_EMAIL="${NEW_EM}"

if [ "\$GIT_COMMITTER_EMAIL" = "\$OLD_EMAIL" ]
then
    export GIT_COMMITTER_NAME="\$CORRECT_NAME"
    export GIT_COMMITTER_EMAIL="\$CORRECT_EMAIL"
fi
if [ "\$GIT_AUTHOR_EMAIL" = "\$OLD_EMAIL" ]
then
export GIT_AUTHOR_NAME="\$CORRECT_NAME"
export GIT_AUTHOR_EMAIL="\$CORRECT_EMAIL"
fi
${CC} --tag-name-filter cat -- --branches --tags
git filter-branch -f --index-filter 'git rm --cached --ignore-unmatch Rakefile' HEAD
EOF
) > $TMP_FILE

    source  ${TMP_FILE}
	cd $here
}

# 在最近一次的提交中替换提交者
function git-commit-change-info-newest() {
    # 新名字
    local NEW_NM=$1
    # 新邮箱
    local NEW_EM=$2
    if [ $# -lt 2 ]; then
        echo need arg :  name email
        return 1
    fi
    git commit --amend --author="$NEW_NM <$NEW_EM>"
}

# 把所有的提交信息修改为新的作者和邮箱
function git-commit-change-info-all-with () {
    # 新名字
    local NEW_NM=$1
    # 新邮箱
    local NEW_EM=$2
    if [ $# -lt 2 ]; then
        echo need arg :  name email
        return 1
    fi
    local CMDLIST=/tmp/.cmd.file
	local here=`pwd`
	git-root

    git log --pretty="%ae" | sort | uniq > $CMDLIST

    for old in `cat $CMDLIST`
    do
		echo "change [$old] -> [$NEW_NM]"
        git-change-cmt-info-all  $old $NEW_NM $NEW_EM || return 1
		echo ""
    done
	cd $here
}
