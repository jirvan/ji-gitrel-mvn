#     ji-gitrel-mvn-1.0.3 - gitrellib.sh
#
#     Copyright (c) 2014,2015 Jirvan Pty Ltd
#     All rights reserved.
#
#     Redistribution and use in source and binary forms, with or without modification,
#     are permitted provided that the following conditions are met:
#
#     * Redistributions of source code must retain the above copyright notice,
#     this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright notice,
#     this list of conditions and the following disclaimer in the documentation
#     and/or other materials provided with the distribution.
#     * Neither the name of Jirvan Pty Ltd nor the names of its contributors
#     may be used to endorse or promote products derived from this software
#     without specific prior written permission.
#
#     THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
#     ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
#     WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
#     DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
#     ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
#     (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
#     LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
#     ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
#     (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
#     SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

function modificationsExist {

    if [ "$1" = "" ]
    then
        local ROOT_DIR="."
    else
        local ROOT_DIR="$1"
    fi

    if [ `git --git-dir="$ROOT_DIR/.git" --work-tree="$ROOT_DIR" status --porcelain|wc -l` -gt 0 ]
    then
        return 0
    else
        return 1
    fi

}

function unpushedCommitsExist {

    if [ "$1" = "" ]
    then
        local ROOT_DIR="."
    else
        local ROOT_DIR="$1"
    fi

    if [ `git --git-dir="$ROOT_DIR/.git" --work-tree="$ROOT_DIR" status|grep 'Your branch is ahead'|wc -l` -gt 0 ]
    then
        return 0
    else
        return 1
    fi

}

function headDetached {

    if [ "$1" = "" ]
    then
        local ROOT_DIR="."
    else
        local ROOT_DIR="$1"
    fi

    if [ `git --git-dir="$ROOT_DIR/.git" --work-tree="$ROOT_DIR" status|grep 'HEAD detached'|wc -l` -gt 0 ]
    then
        return 0
    else
        return 1
    fi

}

function verifyCurrentBranch {

    # Check current branch
    if [ "$1" != "$2" ]
    then
        echo
        echo "ERROR: You are not on the $2 branch (you are on $1)"
        echo
        exit 1
    fi

}

function verifyNoUncommittedChanges {

    # Check there are no uncommitted changes
    if modificationsExist .
    then
        echo
        echo ERROR: There are uncommitted changes
        echo
        exit 1
    fi

}

function verifyNoUnpushedCommits {

    # Check there are no "un-pushed" commits
    if unpushedCommitsExist .
    then
        echo
        echo ERROR: There are \"un-pushed\" commits
        echo
        exit 1
    fi

}

function verifyLocalTagDoesNotExist {

    if git tag|egrep '^'$1'$' >/dev/null
    then
        echo
        echo ERROR: Tag $1 exists
        echo
        exit 1
    fi

}

function verifyTagDoesNotExist {

    if git tag|egrep '^'$1'$' >/dev/null
    then
        echo
        echo ERROR: Tag $1 exists
        echo
        exit 1
    fi

    if git ls-remote --tags origin|egrep '.*refs/tags/'$1'$' >/dev/null
    then
        echo
        echo ERROR: Tag $1 exists at origin
        echo
        exit 1
    fi

}

function verifyPomFileHasASnapshotVersion {

    # Check valid snapshot version in pom file
    if ! mvn blah|egrep '^\[INFO\] Building .+ [0-9]+\.[0-9.]*[0-9]+-SNAPSHOT$' >/dev/null
    then
        echo
        echo ERROR: Project does not seem to have a -SNAPSHOT version
        echo
        exit 1
    fi

}

function extractNonSnapshotVersionIfPresent {

    mvn blah|egrep '^\[INFO\] Building .+ [0-9]+\.[0-9.]*[0-9]+$'|sed 's/^\[INFO\] Building .* //'

}

function extractSnapshotVersionIfPresent {

    mvn blah|egrep '^\[INFO\] Building .+ [0-9]+\.[0-9.]*[0-9]+-SNAPSHOT$'|sed 's/^\[INFO\] Building .* //'

}

function extractVersionFromNonSnapshotVersionIfPresent {

    local SNAPSHOT_VERSION=`extractSnapshotVersionIfPresent`
    if [ "$SNAPSHOT_VERSION" != "" ]
    then
        echo $SNAPSHOT_VERSION | sed 's/-SNAPSHOT$//'
    fi

}

function verifyPomFileHasANonSnapshotVersion {

    # Check valid snapshot version in pom file
    if ! mvn blah|egrep '^\[INFO\] Building .+ [0-9]+\.[0-9.]*[0-9]+$' >/dev/null
    then
        echo
        echo "ERROR: Project does not seem to have a valid (non-SNAPSHOT) version"
        echo
        exit 1
    fi

}

function filterOutInvalidVersions {
    echo $1 | egrep '^[0-9]+\.[0-9.]*[0-9]+$'
}

function verifyHeadIsNotDetached {


    # Check there are no "un-pushed" commits
    if headDetached .
    then
        echo
        echo "ERROR: The head is detached (you are not at the head of the current branch)"
        echo
        exit 1
    fi

}

function confimBeforeProceeding {

    # Confirm before proceeding
    while true; do
        echo
        read -p "$1" yn
        case $yn in
            [Yy] ) break;;
            [Nn] ) echo;exit;;
            * ) echo "   Please answer y or n.";;
        esac
    done
    echo

}

function checkout {

    echo "  - Checking out $1"
    if ! git checkout -q "$1"
    then
        exit 1
    fi

}

function checkoutOnANewBranch {

    echo "  - Creating new branch $1"
    if ! git checkout -q --no-track -b "$1"
    then
        exit 1
    fi

}

function checkoutOnANewBranchAndTrack {

    echo "  - Creating new branch $1"
    if ! git checkout -q --track -b "$1"
    then
        exit 1
    fi

}

function deleteBranch {

    echo "  - Deleting branch $1"
    if ! git branch -q -D "$1"
    then
        exit 1
    fi

}

function updatePomfileVersions {

    if [ "$1" = "" ]
    then
        echo
        echo "ERROR: version must be provided"
        echo
        exit 1
    fi

    echo "  - Setting POM file version to $1"
    if ! mvn versions:set -q -DgenerateBackupPoms=false -DnewVersion=$1 >/dev/null
    then
        exit 1
    fi

}


function updateProjectAndModulePomfileVersions {

   echo Main Project
    updatePomfileVersions $1

    for i in `sed  '1,/^[[:space:]]*<modules>[[:space:]]*$/d' pom.xml \
              | sed  '/^[[:space:]]*<\/modules>[[:space:]]*$/,$d' \
              | grep '^[[:space:]]*<module>.*<\/module>[[:space:]]*$' \
              | sed 's/^[[:space:]]*<module>//' \
              | sed 's/<\/module>[[:space:]]*$//'`;
    do
        echo
        printf "  Module %s\n" $i
        pushd "$i" >/dev/null

        echo "  - Setting  module POM file version to $1"
        if ! mvn versions:set -q -DgenerateBackupPoms=false -DnewVersion=$1 >/dev/null
        then
            echo "    Call to versions:set failed - probably due to this module being a"
            echo "    child project of the main project (in which case not a problem as it"
            echo "    will have been updated automatically along with the main project)."
        fi

        popd >/dev/null
    done

}

function addAllModificationsAndCommitWithMessage {

    echo "  - Adding and committing all modifications"
    if ! git add -A
    then
        exit 1
    fi
    if ! git commit -q -m "$1"
    then
        exit 1
    fi

}

function tagAndPushTagToOrigin {

    echo "  - Creating tag $1 and pushing to origin"
    if ! git tag $1
    then
        exit 1
    fi
    if ! git push -q origin "$1"
    then
        exit 1
    fi

}

function printMostRecentVersion {

    git ls-remote --tags origin | egrep '.*refs/tags/v[0-9]+\.[0-9.]*[0-9]+$'|sed 's,.*refs/tags/v,,'|sort -t . -n -k 1,1 -k 2,2 -k 3,3 -k 4,4 -k 5,5 -k 6,6 -k 7,7 -k 8,8 -k 9,9 | tail -1

}

function printNextVersion {

    local LAST_VERSION=`printMostRecentVersion`
    if [ "$LAST_VERSION" != "" ]
    then

        local MINOR_RELEASE=`echo $LAST_VERSION|sed 's/.*\.//'`
        local NEXT_VERSION=`echo $LAST_VERSION|sed 's/[^.]*$//'`$(($MINOR_RELEASE + 1))
        echo $NEXT_VERSION
    else

        echo "1.0.1"

    fi

}

function printMostRecentBranchVersionFor {

    local PARENT_VERSION=$1

    git ls-remote --tags origin | egrep '.*refs/tags/v'"$PARENT_VERSION"'\.[0-9][0-9]*$'|sed 's,.*refs/tags/v,,'|sort -t . -n -k 1,1 -k 2,2 -k 3,3 -k 4,4 -k 5,5 -k 6,6 -k 7,7 -k 8,8 -k 9,9 | tail -1

}


function printNextBranchVersionFor {

    local PARENT_VERSION=$1
    local LAST_BRANCH_VERSION=`printMostRecentBranchVersionFor $PARENT_VERSION`
    if [ "$LAST_BRANCH_VERSION" != "" ]
    then

        local MINOR_RELEASE=`echo $LAST_BRANCH_VERSION|sed 's/.*\.//'`
        local NEXT_BRANCH_VERSION=`echo $LAST_BRANCH_VERSION|sed 's/[^.]*$//'`$(($MINOR_RELEASE + 1))
        echo $NEXT_BRANCH_VERSION

    else

        echo $PARENT_VERSION".1"

    fi

}

function printSerialVersion {

    local LAST_VERSION=$1
    if [ "$LAST_VERSION" != "" ]
    then
        local MINOR_RELEASE=`echo $LAST_VERSION|sed 's/.*\.//'`
        local NEXT_VERSION=`echo $LAST_VERSION|sed 's/[^.]*$//'`$(($MINOR_RELEASE + 1))
        echo $NEXT_VERSION
    else
        echo
        echo ERROR: Parameter 1 for printSerialVersion must not be ""
        echo
        exit 1
    fi

}

function verifyIsNextVersion {

    local _NEXT_VERSION=`printNextVersion`
    if [ "$_NEXT_VERSION" = "" ]
    then
        return 0
    fi
    if [ "$1" != "$_NEXT_VERSION" ]
    then
        echo
        echo "ERROR: $1 is not the next version ($_NEXT_VERSION)"
        echo
        exit 1
    fi

}

function chooseReleaseCandidateVersion {

    local candidates=( $(git ls-remote --tags origin | egrep '.*refs/tags/v[0-9]+\.[0-9.]*[0-9]+_rc[0-9]+$'|sed 's,.*refs/tags/v,,') )

    if [ ${#candidates[@]} -lt 1 ]
    then
        echo
        echo "ERROR: There are no release candidates currently available"
        echo "       from which to create a release"
        echo
        exit 1
    elif [ ${#candidates[@]} -eq 1 ]
    then
        echo
        echo "   There is currently only one release candidate (${candidates[0]})"
        RELEASE_CANDIDATE_VERSION=${candidates[0]}
        return 0
    else
        echo
        echo "  Please choose a release candidate"
        echo
    fi

    for i in `seq 0 $((${#candidates[@]} - 1))`;
    do
        printf "  %3d:  %s\n" $(($i + 1)) ${candidates[$i]}
    done

    local CHOICE=""
    while true; do
        echo
        if [ "$CHOICE" != "" ]
        then
            read -p "   Choose a number [$CHOICE] ? " value
        else
            read -p "   Choose a number ? " value
        fi
        if [ "$value" != "" ]
        then
            let numberChoice=0+$value
            if [ $numberChoice -lt 1 ] || [ $numberChoice -gt ${#candidates[@]} ]
            then
                echo "   $value is not a valid choice, please re-enter"
            else
                local CHOICE="$numberChoice"
                break
            fi
        else
            echo "   Please enter the number of the item to choose"
        fi
    done

    RELEASE_CANDIDATE_VERSION=${candidates[$(($CHOICE - 1))]}

}

function archiveRedundantReleaseCandidateTags {

    local RELEASE_VERSION="$1"
    local candidates=( $(git ls-remote --tags origin | egrep '.*refs/tags/v'$RELEASE_VERSION'_rc[0-9]+$'|sed 's,.*refs/tags/v,,') )

    for i in `seq 0 $((${#candidates[@]} - 1))`;
    do

        local oldTag="v${candidates[$i]}"
        local archiveTag="archive/v${candidates[$i]}"

        echo "  - Creating tag $archiveTag and pushing to origin"
        if ! git tag "$archiveTag" "$oldTag"
        then
            exit 1
        fi
        if ! git push -q origin "$archiveTag"
        then
            exit 1
        fi
        echo "  - Deleting tag $oldTag locally and at origin"
        if ! git tag -d $oldTag >/dev/null
        then
            exit 1
        fi
        if ! git push origin :"$oldTag" 2>/dev/null
        then
            exit 1
        fi

    done

}


function archiveIfNecessaryAndRemoveRedundantReleaseCandidateTags {

    local RELEASE_VERSION="$1"
    local candidates=( $(git ls-remote --tags origin | egrep '.*refs/tags/v'$RELEASE_VERSION'_rc[0-9]+$'|sed 's,.*refs/tags/v,,') )

    for i in `seq 0 $((${#candidates[@]} - 1))`;
    do

        local oldTag="v${candidates[$i]}"
        local archiveTag="archive/v${candidates[$i]}"

        if ! git ls-remote --tags origin|egrep '.*refs/tags/'$archiveTag'$' >/dev/null
            then
            echo "  - Creating tag $archiveTag and pushing to origin"
            if ! git tag "$archiveTag" "$oldTag"
            then
                exit 1
            fi
            if ! git push -q origin "$archiveTag"
            then
                exit 1
            fi
        fi

        echo "  - Deleting tag $oldTag locally and at origin"
        if ! git tag -d $oldTag >/dev/null
        then
            exit 1
        fi
        if ! git push origin :"$oldTag" 2>/dev/null
        then
            exit 1
        fi

    done

}
