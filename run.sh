#!/usr/bin/env bash

USER_PID_REGEX="[A-Z0-9]{4}-[A-Z0-9]{3}"
FAMILY_FOLDER=family

if [ "$1" == "" ] || [[ ! "$1" =~ ${USER_PID_REGEX} ]]; then
    echo "Please provide the argument with the format ABCD-123"
    exit 1
fi

ID=$1
YEAR_LIMIT="${2:-1400}"

echo "Search will be done until $YEAR_LIMIT."

echo "Create family folder.."
mkdir -p $FAMILY_FOLDER

get_user_from_api() {
    ret="https://api.familysearch.org/platform/tree/persons/$1.json"
    #ret="https://api.familysearch.org/platform/tree/persons/$1/parents.json"
    #ret="https://api.familysearch.org/platform/tree/child-and-parents-relationships/$1.json"
}

get_json_from() {
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
    echo "User: $NAME ($1) "
    echo " Parent1: " $PARENT1
    echo " Parent2: " $PARENT2
}

get_year() {
    ret=$(jql '"persons"[0]."facts"[0]."date"."original"' family/$1.json | rg '\d+"' -o | tr --delete \")
}

LAST_IDS_SIZE=1
IDS=($ID)
while true; do
    INDEX=0
    AMOUNT=${#IDS[@]}
    LAST_IDS_SIZE=$AMOUNT

    for ID_I in ${IDS[*]}; do
        INDEX=$(($INDEX+1))
        echo "$INDEX / $AMOUNT"

        get_json_from $ID_I
        get_year $ID_I
        echo "Year:" $ret
        if [ "$ret" != "" ] && (( $ret < $YEAR_LIMIT )); then
            echo "Skipping.."
            continue
        fi
        get_parents $ID_I
        IDS+=("$PARENT1")
        IDS+=("$PARENT2")
    done
    IDS=( `for i in ${IDS[@]}; do echo $i; done | sort -u` )
    if (( $LAST_IDS_SIZE == ${#IDS[@]} )); then
        echo "$ID $YEAR_LIMIT" > $FAMILY_FOLDER/results.txt
        echo "${IDS[@]}" >> $FAMILY_FOLDER/results.txt
        break
    fi
done
