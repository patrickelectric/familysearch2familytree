#!/usr/bin/env bash

USER_PID_REGEX="[A-Z0-9]{4}-[A-Z0-9]{3}"
FAMILY_FOLDER=family

if [ "$1" == "" ] || [[ ! "$1" =~ ${USER_PID_REGEX} ]]; then
    echo "Please provide the argument with the format ABCD-123"
    exit 1
fi

ID=$1

echo "Create family folder.."
mkdir -p $FAMILY_FOLDER

get_user_from_api() {
    ret="https://api.familysearch.org/platform/tree/persons/$1.json"
    #ret="https://api.familysearch.org/platform/tree/persons/$1/parents.json"
    #ret="https://api.familysearch.org/platform/tree/child-and-parents-relationships/$1.json"
}

get_json_from() {
    ID=$1
    echo "Looking for: $1"

    if [ -f "$FAMILY_FOLDER/$1.json" ]; then
        echo "$1.json exist"
        return
    fi

    get_user_from_api $1
    curl --cookie ~/cookies.txt $ret -o $FAMILY_FOLDER/$1.json
}

get_parents() {
    NAME=$(jql '"persons"[0]."display"."name"' $FAMILY_FOLDER/$1.json | tr --delete \")
    PARENT1=$(jql '"childAndParentsRelationships"[0]."parent1"."resourceId"' $FAMILY_FOLDER/$1.json | tr --delete \")
    PARENT2=$(jql '"childAndParentsRelationships"[0]."parent2"."resourceId"' $FAMILY_FOLDER/$1.json | tr --delete \")
    echo "User: " $NAME
    echo " Parent1: " $PARENT1
    echo " Parent2: " $PARENT2
}

LAST_IDS=()
IDS=($ID)
while [[ ${#LAST_IDS[@]} != ${#IDS[@]} ]]; do
    LAST_IDS=$IDS
    for ID in ${IDS[*]}; do
        get_json_from $ID
        get_parents $ID
        IDS+=("$PARENT1")
        IDS+=("$PARENT2")
    done
    IDS=( `for i in ${IDS[@]}; do echo $i; done | sort -u` )
done
