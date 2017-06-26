#!/bin/sh

pl_list=( "default.rgw.data.root" ".rgw.root" "default.rgw.control" "default.rgw.gc" "default.rgw.buckets.data" "default.rgw.buckets.index" "default.rgw.buckets.extra" "default.rgw.log" "default.rgw.meta" "default.rgw.intent-log" "default.rgw.usage" "default.rgw.users" "default.rgw.users.email" "default.rgw.users.swift" "default.rgw.users.uid")
pg=32
pg_data=1024
pg_index=64
k=6
m=3


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
    if [ $pl == "default.rgw.buckets.data" ]
    then
        ceph osd pool create $pl $pg_data replicated
    elif [ $pl == "default.rgw.buckets.index" ]
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
    if [ $pl == "default.rgw.buckets.data" ]
    then
        ceph osd pool create $pl $pg_data $pg_data erasure myprofile
    elif [ $pl == "default.rgw.buckets.index" ]
    then
        ceph osd pool create $pl $pg_index replicated
    else
        ceph osd pool create $pl $pg replicated

    fi
done
}

while getopts r:h:d OPTION
do
 case "${OPTION}" in
 r) REPLICATION=${OPTARG};;
 h) echo "usage ./scrit -r [rep | ec]"
    exit 1
 ;;
 d) delete_pools;;
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

