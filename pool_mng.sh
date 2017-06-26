#!/bin/sh

pl_list=(".rgw.root" ".rgw.control" ".rgw.gc" ".rgw.buckets" ".rgw.buckets.index" ".rgw.buckets.extra" ".log" ".intent-log" ".usage" ".users" ".users.email" ".users.swift" ".users.uid")
pg=32
pg_data=2048
pg_index=128
k=4
m=2


function delete_pools {
for pl in ${pl_list[@]}
do
    if [ $pl != "rbd" ]
    then 
	ceph osd pool delete $pl $pl --yes-i-really-really-mean-it
    fi
done

sleep 5
}

function replication {
for pl in ${pl_list[@]}
do
    if [ $pl == ".rgw.buckets" ]
    then
        ceph osd pool create $pl $pg_data replicated
    elif [ $pl == ".rgw.buckets.index" ]
    then
        ceph osd pool create $pl $pg_index replicated
    else
        ceph osd pool create $pl $pg replicated

    fi
done
}

function ec {

ceph osd erasure-code-profile rm myprofile
ceph osd erasure-code-profile set myprofile k=$k m=$m ruleset-failure-domain=osd

for pl in ${pl_list[@]}
do
    if [ $pl == ".rgw.buckets" ]
    then
        ceph osd pool create $pl $pg_data replicated
    elif [ $pl == ".rgw.buckets.index" ]
    then
        ceph osd pool create $pl $pg_index erasure myprofile
    else
        ceph osd pool create $pl $pg replicated

    fi
done
}

while getopts r:h OPTION
do
 case "${OPTION}" in
 r) REPLICATION=${OPTARG};;
 h) echo "usage ./scrit -r [rep | ec]"
    exit 1
 ;;
 *)echo "usage ./scrit -r [rep | ec]"
   exit 1
 ;;
 esac
done


if [ "$REPLICATION" == "rep" ]
   then
   delete_pools
   replication
   
elif [ "$REPLICATION" == "ec" ]
   then
   delete_pools
   ec
fi

