#!/bin/bash


while getopts "a:u:" opt; do
  case $opt in
    a)  action=$OPTARG ;;
    u)  user=$OPTARG ;;
    *)
      echo "$0 -a action [stop|start] -u user" >&2
      exit 1
      ;;
  esac
done


[ -z $action ] && echo "missing action" >&2 && exit 1
[ -z $user ] && echo "missing user" >&2 && exit 1

