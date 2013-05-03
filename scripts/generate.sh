#!/bin/bash


if [ $# -lt 1 ]
then
  echo "usage:"
  echo "./generate.sh [user_id]"
  echo "./generate.sh [user_id] debug"
  exit
fi

user_id=$1
viewer_id=100000546890088 # test user

scripts_dir=$HOME/www/scripts/timeline/prototypes/zoom/
data_folder=$HOME/code/sandbox/public/data/
if [ ! -d $data_folder ]
then
  mkdir $data_folder
fi

output_file=$data_folder/$((user_id))_timeline.json

if [ $2 == 'debug' ]
then
  hphpd -f $scripts_dir/load_user.php --arg="--viewer_id=$viewer_id" --arg="--user_id=$user_id"
else
  $scripts_dir/load_friends.php $user_id $viewer_id \
    > $data_folder/$((user_id))_friends.tsv

  $scripts_dir/user_table_to_json.py $data_folder/$((user_id))_friends.tsv \
    > $data_folder/$((user_id))_friends.json

  $scripts_dir/load_user.php --viewer_id=$viewer_id --user_id=$user_id \
    > $output_file
fi

echo -e "\nData exported to $output_file\nVisit prototype at:\n"
echo -e "\thttp://www.shuw.sb.facebook.com:8090/trailer?user=$user_id\n"
