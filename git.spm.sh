#!/bin/bash

function git-spm-till-lias-tag () {
    local last_tag_id=`git log --decorate | grep "tag:" | awk '{print$2}' | head -n 1 | cut -c 1-20`
	local file=/tmp/.git.id.after.$last_tag_id.$$.list
	local cmf=/tmp/.git.id.after.$last_tag_id.$$.commit
	rm $file -rf; touch $file
	## 从所有的commit中，获取 上一个tag 以后 的 提交点
    git --no-pager log --pretty=tformat:"%H" | while read commit_id
	do
        local id=`echo $commit_id  | cut -c 1-20`
        if [ "$id" = "$last_tag_id" ]; then
			break
		else
			# 初步过滤掉无关的 提交（merge）
			local merge=`git --no-pager log --pretty=tformat:"[%h] : [%cN] : %s" -n 1 "$id" | grep "Merge "`
            if [ -z "$merge" ]; then
				#empty
				echo $id >> $file
				#echo "Add commit $id"
			#else
            #   echo "Skip merge $id"
			fi
			
		fi
	done
	cat $file | while read commit_id
    do
        #git --no-pager log --pretty=tformat:"[%cN]%n%f%b" "$commit_id" -n 1 | grep -v "Change-Id"
        local change_id=`git --no-pager log --pretty=tformat:"[%cN]%n%s%n%b%n" "$commit_id" -n 1 | grep "Change-Id" | awk '{print$2}' | cut -c 1-10`
        echo -n "$change_id "
        git --no-pager log --pretty=tformat:"[%cN] %s%n%b" "$commit_id" -n 1 | grep -v "Change-Id" | head -n 10 | tr -s '\n'
        cat <<EOF
<Jira ID  >: 
<Jira 标题>: 
<测试 步骤>: 


EOF
    done
    rm $file -rf
}
#git-spm-till-lias-tag
