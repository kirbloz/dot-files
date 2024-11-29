#!/bin/sh

PROGRESS_CURR=0
PROGRESS_TOTAL=287                         

# This file was autowritten by rmlint
# rmlint was executed from: /home/giovanni/.local/bin/
# Your command line was: rmlint /home/giovanni

RMLINT_BINARY="/usr/bin/rmlint"

# Only use sudo if we're not root yet:
# (See: https://github.com/sahib/rmlint/issues/27://github.com/sahib/rmlint/issues/271)
SUDO_COMMAND="sudo"
if [ "$(id -u)" -eq "0" ]
then
  SUDO_COMMAND=""
fi

USER='giovanni'
GROUP='giovanni'

# Set to true on -n
DO_DRY_RUN=

# Set to true on -p
DO_PARANOID_CHECK=

# Set to true on -r
DO_CLONE_READONLY=

# Set to true on -q
DO_SHOW_PROGRESS=true

# Set to true on -c
DO_DELETE_EMPTY_DIRS=

# Set to true on -k
DO_KEEP_DIR_TIMESTAMPS=

# Set to true on -i
DO_ASK_BEFORE_DELETE=

##################################
# GENERAL LINT HANDLER FUNCTIONS #
##################################

COL_RED='[0;31m'
COL_BLUE='[1;34m'
COL_GREEN='[0;32m'
COL_YELLOW='[0;33m'
COL_RESET='[0m'

print_progress_prefix() {
    if [ -n "$DO_SHOW_PROGRESS" ]; then
        PROGRESS_PERC=0
        if [ $((PROGRESS_TOTAL)) -gt 0 ]; then
            PROGRESS_PERC=$((PROGRESS_CURR * 100 / PROGRESS_TOTAL))
        fi
        printf '%s[%3d%%]%s ' "${COL_BLUE}" "$PROGRESS_PERC" "${COL_RESET}"
        if [ $# -eq "1" ]; then
            PROGRESS_CURR=$((PROGRESS_CURR+$1))
        else
            PROGRESS_CURR=$((PROGRESS_CURR+1))
        fi
    fi
}

handle_emptyfile() {
    print_progress_prefix
    echo "${COL_GREEN}Deleting empty file:${COL_RESET} $1"
    if [ -z "$DO_DRY_RUN" ]; then
        rm -f "$1"
    fi
}

handle_emptydir() {
    print_progress_prefix
    echo "${COL_GREEN}Deleting empty directory: ${COL_RESET}$1"
    if [ -z "$DO_DRY_RUN" ]; then
        rmdir "$1"
    fi
}

handle_bad_symlink() {
    print_progress_prefix
    echo "${COL_GREEN} Deleting symlink pointing nowhere: ${COL_RESET}$1"
    if [ -z "$DO_DRY_RUN" ]; then
        rm -f "$1"
    fi
}

handle_unstripped_binary() {
    print_progress_prefix
    echo "${COL_GREEN} Stripping debug symbols of: ${COL_RESET}$1"
    if [ -z "$DO_DRY_RUN" ]; then
        strip -s "$1"
    fi
}

handle_bad_user_id() {
    print_progress_prefix
    echo "${COL_GREEN}chown ${USER}${COL_RESET} $1"
    if [ -z "$DO_DRY_RUN" ]; then
        chown "$USER" "$1"
    fi
}

handle_bad_group_id() {
    print_progress_prefix
    echo "${COL_GREEN}chgrp ${GROUP}${COL_RESET} $1"
    if [ -z "$DO_DRY_RUN" ]; then
        chgrp "$GROUP" "$1"
    fi
}

handle_bad_user_and_group_id() {
    print_progress_prefix
    echo "${COL_GREEN}chown ${USER}:${GROUP}${COL_RESET} $1"
    if [ -z "$DO_DRY_RUN" ]; then
        chown "$USER:$GROUP" "$1"
    fi
}

###############################
# DUPLICATE HANDLER FUNCTIONS #
###############################

check_for_equality() {
    if [ -f "$1" ]; then
        # Use the more lightweight builtin `cmp` for regular files:
        cmp -s "$1" "$2"
        echo $?
    else
        # Fallback to `rmlint --equal` for directories:
        "$RMLINT_BINARY" -p --equal  "$1" "$2"
        echo $?
    fi
}

original_check() {
    if [ ! -e "$2" ]; then
        echo "${COL_RED}^^^^^^ Error: original has disappeared - cancelling.....${COL_RESET}"
        return 1
    fi

    if [ ! -e "$1" ]; then
        echo "${COL_RED}^^^^^^ Error: duplicate has disappeared - cancelling.....${COL_RESET}"
        return 1
    fi

    # Check they are not the exact same file (hardlinks allowed):
    if [ "$1" = "$2" ]; then
        echo "${COL_RED}^^^^^^ Error: original and duplicate point to the *same* path - cancelling.....${COL_RESET}"
        return 1
    fi

    # Do double-check if requested:
    if [ -z "$DO_PARANOID_CHECK" ]; then
        return 0
    else
        if [ "$(check_for_equality "$1" "$2")" -ne "0" ]; then
            echo "${COL_RED}^^^^^^ Error: files no longer identical - cancelling.....${COL_RESET}"
            return 1
        fi
    fi
}

cp_symlink() {
    print_progress_prefix
    echo "${COL_YELLOW}Symlinking to original: ${COL_RESET}$1"
    if original_check "$1" "$2"; then
        if [ -z "$DO_DRY_RUN" ]; then
            # replace duplicate with symlink
            rm -rf "$1"
            ln -s "$2" "$1"
            # make the symlink's mtime the same as the original
            touch -mr "$2" -h "$1"
        fi
    fi
}

cp_hardlink() {
    if [ -d "$1" ]; then
        # for duplicate dir's, can't hardlink so use symlink
        cp_symlink "$@"
        return $?
    fi
    print_progress_prefix
    echo "${COL_YELLOW}Hardlinking to original: ${COL_RESET}$1"
    if original_check "$1" "$2"; then
        if [ -z "$DO_DRY_RUN" ]; then
            # replace duplicate with hardlink
            rm -rf "$1"
            ln "$2" "$1"
        fi
    fi
}

cp_reflink() {
    if [ -d "$1" ]; then
        # for duplicate dir's, can't clone so use symlink
        cp_symlink "$@"
        return $?
    fi
    print_progress_prefix
    # reflink $1 to $2's data, preserving $1's  mtime
    echo "${COL_YELLOW}Reflinking to original: ${COL_RESET}$1"
    if original_check "$1" "$2"; then
        if [ -z "$DO_DRY_RUN" ]; then
            touch -mr "$1" "$0"
            if [ -d "$1" ]; then
                rm -rf "$1"
            fi
            cp --archive --reflink=always "$2" "$1"
            touch -mr "$0" "$1"
        fi
    fi
}

clone() {
    print_progress_prefix
    # clone $1 from $2's data
    # note: no original_check() call because rmlint --dedupe takes care of this
    echo "${COL_YELLOW}Cloning to: ${COL_RESET}$1"
    if [ -z "$DO_DRY_RUN" ]; then
        if [ -n "$DO_CLONE_READONLY" ]; then
            $SUDO_COMMAND $RMLINT_BINARY --dedupe  --dedupe-readonly "$2" "$1"
        else
            $RMLINT_BINARY --dedupe  "$2" "$1"
        fi
    fi
}

skip_hardlink() {
    print_progress_prefix
    echo "${COL_BLUE}Leaving as-is (already hardlinked to original): ${COL_RESET}$1"
}

skip_reflink() {
    print_progress_prefix
    echo "${COL_BLUE}Leaving as-is (already reflinked to original): ${COL_RESET}$1"
}

user_command() {
    print_progress_prefix

    echo "${COL_YELLOW}Executing user command: ${COL_RESET}$1"
    if [ -z "$DO_DRY_RUN" ]; then
        # You can define this function to do what you want:
        echo 'no user command defined.'
    fi
}

remove_cmd() {
    print_progress_prefix
    echo "${COL_YELLOW}Deleting: ${COL_RESET}$1"
    if original_check "$1" "$2"; then
        if [ -z "$DO_DRY_RUN" ]; then
            if [ -n "$DO_KEEP_DIR_TIMESTAMPS" ]; then
                touch -r "$(dirname "$1")" "$STAMPFILE"
            fi
            if [ -n "$DO_ASK_BEFORE_DELETE" ]; then
              rm -ri "$1"
            else
              rm -rf "$1"
            fi
            if [ -n "$DO_KEEP_DIR_TIMESTAMPS" ]; then
                # Swap back old directory timestamp:
                touch -r "$STAMPFILE" "$(dirname "$1")"
                rm "$STAMPFILE"
            fi

            if [ -n "$DO_DELETE_EMPTY_DIRS" ]; then
                DIR=$(dirname "$1")
                while [ ! "$(ls -A "$DIR")" ]; do
                    print_progress_prefix 0
                    echo "${COL_GREEN}Deleting resulting empty dir: ${COL_RESET}$DIR"
                    rmdir "$DIR"
                    DIR=$(dirname "$DIR")
                done
            fi
        fi
    fi
}

original_cmd() {
    print_progress_prefix
    echo "${COL_GREEN}Keeping:  ${COL_RESET}$1"
}

##################
# OPTION PARSING #
##################

ask() {
    cat << EOF

This script will delete certain files rmlint found.
It is highly advisable to view the script first!

Rmlint was executed in the following way:

   $ rmlint /home/giovanni

Execute this script with -d to disable this informational message.
Type any string to continue; CTRL-C, Enter or CTRL-D to abort immediately
EOF
    read -r eof_check
    if [ -z "$eof_check" ]
    then
        # Count Ctrl-D and Enter as aborted too.
        echo "${COL_RED}Aborted on behalf of the user.${COL_RESET}"
        exit 1;
    fi
}

usage() {
    cat << EOF
usage: $0 OPTIONS

OPTIONS:

  -h   Show this message.
  -d   Do not ask before running.
  -x   Keep rmlint.sh; do not autodelete it.
  -p   Recheck that files are still identical before removing duplicates.
  -r   Allow deduplication of files on read-only btrfs snapshots. (requires sudo)
  -n   Do not perform any modifications, just print what would be done. (implies -d and -x)
  -c   Clean up empty directories while deleting duplicates.
  -q   Do not show progress.
  -k   Keep the timestamp of directories when removing duplicates.
  -i   Ask before deleting each file
EOF
}

DO_REMOVE=
DO_ASK=

while getopts "dhxnrpqcki" OPTION
do
  case $OPTION in
     h)
       usage
       exit 0
       ;;
     d)
       DO_ASK=false
       ;;
     x)
       DO_REMOVE=false
       ;;
     n)
       DO_DRY_RUN=true
       DO_REMOVE=false
       DO_ASK=false
       DO_ASK_BEFORE_DELETE=false
       ;;
     r)
       DO_CLONE_READONLY=true
       ;;
     p)
       DO_PARANOID_CHECK=true
       ;;
     c)
       DO_DELETE_EMPTY_DIRS=true
       ;;
     q)
       DO_SHOW_PROGRESS=
       ;;
     k)
       DO_KEEP_DIR_TIMESTAMPS=true
       STAMPFILE=$(mktemp 'rmlint.XXXXXXXX.stamp')
       ;;
     i)
       DO_ASK_BEFORE_DELETE=true
       ;;
     *)
       usage
       exit 1
  esac
done

if [ -z $DO_REMOVE ]
then
    echo "#${COL_YELLOW} ///${COL_RESET}This script will be deleted after it runs${COL_YELLOW}///${COL_RESET}"
fi

if [ -z $DO_ASK ]
then
  usage
  ask
fi

if [ -n "$DO_DRY_RUN" ]
then
    echo "#${COL_YELLOW} ////////////////////////////////////////////////////////////${COL_RESET}"
    echo "#${COL_YELLOW} /// ${COL_RESET} This is only a dry run; nothing will be modified! ${COL_YELLOW}///${COL_RESET}"
    echo "#${COL_YELLOW} ////////////////////////////////////////////////////////////${COL_RESET}"
fi

######### START OF AUTOGENERATED OUTPUT #########

handle_emptydir '/home/giovanni/yay/pkg/yay/usr/share/zsh/site-functions' # empty folder
handle_emptydir '/home/giovanni/yay/pkg/yay/usr/share/zsh' # empty folder
handle_emptydir '/home/giovanni/yay/pkg/yay/usr/share/fish/vendor_completions.d' # empty folder
handle_emptydir '/home/giovanni/yay/pkg/yay/usr/share/fish' # empty folder
handle_emptydir '/home/giovanni/yay/pkg/yay/usr/share/bash-completion/completions' # empty folder
handle_emptydir '/home/giovanni/yay/pkg/yay/usr/share/bash-completion' # empty folder
handle_emptydir '/home/giovanni/custom/system/tmp/1729846765951' # empty folder
handle_emptydir '/home/giovanni/custom/system/testHistory/d4ef4cf3' # empty folder
handle_emptydir '/home/giovanni/custom/system/testHistory/65ca5cca' # empty folder
handle_emptydir '/home/giovanni/custom/system/testHistory/22e424f4' # empty folder
handle_emptydir '/home/giovanni/custom/system/terminal/history' # empty folder
handle_emptydir '/home/giovanni/custom/system/terminal' # empty folder
handle_emptydir '/home/giovanni/custom/system/projects/progetto-se.c3023696/indexingStamp' # empty folder
handle_emptydir '/home/giovanni/custom/system/projects/progetto-se-2.1.0.22e424f4/indexingStamp' # empty folder
handle_emptydir '/home/giovanni/custom/system/projects/progetto-se-2.1.0.22e424f4/external_build_system/project' # empty folder
handle_emptydir '/home/giovanni/custom/system/index/stubs/vuex.store.index' # empty folder
handle_emptydir '/home/giovanni/custom/system/index/stubs/vue.url.index' # empty folder
handle_emptydir '/home/giovanni/custom/system/index/stubs/vue.options.index' # empty folder
handle_emptydir '/home/giovanni/custom/system/index/stubs/vue.mixin.binding.index' # empty folder
handle_emptydir '/home/giovanni/custom/system/index/stubs/vue.id.index' # empty folder
handle_emptydir '/home/giovanni/custom/system/index/stubs/vue.global.filters.index' # empty folder
handle_emptydir '/home/giovanni/custom/system/index/stubs/vue.global.directives.index' # empty folder
handle_emptydir '/home/giovanni/custom/system/index/stubs/ts.local.classes' # empty folder
handle_emptydir '/home/giovanni/custom/system/index/stubs/ts.external.module.name.index' # empty folder
handle_emptydir '/home/giovanni/custom/system/index/stubs/ts.external.module.index' # empty folder
handle_emptydir '/home/giovanni/custom/system/index/stubs/ts.embedded.content.index' # empty folder
handle_emptydir '/home/giovanni/custom/system/index/stubs/sql.table.shortname' # empty folder
handle_emptydir '/home/giovanni/custom/system/index/stubs/sql.names' # empty folder
handle_emptydir '/home/giovanni/custom/system/index/stubs/sql.column.name' # empty folder
handle_emptydir '/home/giovanni/custom/system/index/stubs/scss.placeholder.selector' # empty folder
handle_emptydir '/home/giovanni/custom/system/index/stubs/redis.dml.shortname' # empty folder
handle_emptydir '/home/giovanni/custom/system/index/stubs/protobuf.byshortname' # empty folder
handle_emptydir '/home/giovanni/custom/system/index/stubs/protobuf.byqualifiedname' # empty folder
handle_emptydir '/home/giovanni/custom/system/index/stubs/postcss.custom.selector' # empty folder
handle_emptydir '/home/giovanni/custom/system/index/stubs/postcss.custom.media' # empty folder
handle_emptydir '/home/giovanni/custom/system/index/stubs/org.jetbrains.kotlin.idea.stubindex.kotlintoplevelpropertyfqnnameindex' # empty folder
handle_emptydir '/home/giovanni/custom/system/index/stubs/org.jetbrains.kotlin.idea.stubindex.kotlinsubclassobjectnameindex' # empty folder
handle_emptydir '/home/giovanni/custom/system/index/stubs/org.jetbrains.kotlin.idea.stubindex.kotlinscriptfqnindex' # empty folder
handle_emptydir '/home/giovanni/custom/system/index/stubs/org.jetbrains.kotlin.idea.stubindex.kotlinjvmnameannotationindex' # empty folder
handle_emptydir '/home/giovanni/custom/system/index/stubs/org.jetbrains.kotlin.idea.stubindex.kotlininnertypealiasclassidindex' # empty folder
handle_emptydir '/home/giovanni/custom/system/index/stubs/less.variables' # empty folder
handle_emptydir '/home/giovanni/custom/system/index/stubs/less.mixins' # empty folder
handle_emptydir '/home/giovanni/custom/system/index/stubs/kotlintoplevelpropertybypackageindex' # empty folder
handle_emptydir '/home/giovanni/custom/system/index/stubs/kotlinprobablynothingpropertyshortnameindex' # empty folder
handle_emptydir '/home/giovanni/custom/system/index/stubs/kotlinoverridableinternalmembersshortnameindex' # empty folder
handle_emptydir '/home/giovanni/custom/system/index/stubs/kotlinextensionsinobjectsbyreceivertypeindex' # empty folder
handle_emptydir '/home/giovanni/custom/system/index/stubs/js.used.remote.modules' # empty folder
handle_emptydir '/home/giovanni/custom/system/index/stubs/js.typedef.index2' # empty folder
handle_emptydir '/home/giovanni/custom/system/index/stubs/js.qualified.shortname' # empty folder
handle_emptydir '/home/giovanni/custom/system/index/stubs/js.lazy.packages' # empty folder
handle_emptydir '/home/giovanni/custom/system/index/stubs/js.imported.bindings.index' # empty folder
handle_emptydir '/home/giovanni/custom/system/index/stubs/js.gcl.modules' # empty folder
handle_emptydir '/home/giovanni/custom/system/index/stubs/js.exported.index' # empty folder
handle_emptydir '/home/giovanni/custom/system/index/stubs/js.export.default.react.component.index' # empty folder
handle_emptydir '/home/giovanni/custom/system/index/stubs/js.element.qualifiedname' # empty folder
handle_emptydir '/home/giovanni/custom/system/index/stubs/js.doc.modules' # empty folder
handle_emptydir '/home/giovanni/custom/system/index/stubs/js.class.super' # empty folder
handle_emptydir '/home/giovanni/custom/system/index/stubs/js.class.implements' # empty folder
handle_emptydir '/home/giovanni/custom/system/index/stubs/java.unnamed.class' # empty folder
handle_emptydir '/home/giovanni/custom/system/index/stubs/gr.field.name' # empty folder
handle_emptydir '/home/giovanni/custom/system/index/stubs/gr.class.super' # empty folder
handle_emptydir '/home/giovanni/custom/system/index/stubs/gr.class.fqn.s' # empty folder
handle_emptydir '/home/giovanni/custom/system/index/stubs/gr.anonymous.class' # empty folder
handle_emptydir '/home/giovanni/custom/system/index/stubs/gr.annot.method.name' # empty folder
handle_emptydir '/home/giovanni/custom/system/index/stubs/gr.annot.members' # empty folder
handle_emptydir '/home/giovanni/custom/system/index/stubs/es6.exported.index' # empty folder
handle_emptydir '/home/giovanni/custom/system/index/stubs/es6.assignment.index' # empty folder
handle_emptydir '/home/giovanni/custom/system/index/stubs/dom.namespacekey' # empty folder
handle_emptydir '/home/giovanni/custom/system/index/stubs/dom.elementclass' # empty folder
handle_emptydir '/home/giovanni/custom/system/index/stubs/css.custom.property' # empty folder
handle_emptydir '/home/giovanni/custom/system/index/stubs/css.custom.mixin' # empty folder
handle_emptydir '/home/giovanni/custom/system/index/stubs/angular2.templateurl.index' # empty folder
handle_emptydir '/home/giovanni/custom/system/index/stubs/angular2.symbol.index' # empty folder
handle_emptydir '/home/giovanni/custom/system/index/stubs/angular2.source.pipe.index' # empty folder
handle_emptydir '/home/giovanni/custom/system/index/stubs/angular2.source.module.index' # empty folder
handle_emptydir '/home/giovanni/custom/system/index/stubs/angular2.source.directive.index' # empty folder
handle_emptydir '/home/giovanni/custom/system/index/stubs/angular2.metadata.pipe.index' # empty folder
handle_emptydir '/home/giovanni/custom/system/index/stubs/angular2.metadata.node.index' # empty folder
handle_emptydir '/home/giovanni/custom/system/index/stubs/angular2.metadata.module.index' # empty folder
handle_emptydir '/home/giovanni/custom/system/index/stubs/angular2.metadata.function.index' # empty folder
handle_emptydir '/home/giovanni/custom/system/index/stubs/angular2.metadata.directive.index' # empty folder
handle_emptydir '/home/giovanni/custom/system/index/stubs/angular2.metadata.classname.index' # empty folder
handle_emptydir '/home/giovanni/custom/system/index/stubs/angular2.ivy.pipe.index' # empty folder
handle_emptydir '/home/giovanni/custom/system/index/stubs/angular2.ivy.module.index' # empty folder
handle_emptydir '/home/giovanni/custom/system/index/stubs/angular2.ivy.directive.index' # empty folder
handle_emptydir '/home/giovanni/custom/system/index/stubs/amd.requirepaths.index' # empty folder
handle_emptydir '/home/giovanni/custom/system/index/stubs/amd.baseurl.index' # empty folder
handle_emptydir '/home/giovanni/custom/system/index/shared_indexes/sih.yaml.keys.name' # empty folder
handle_emptydir '/home/giovanni/custom/system/index/shared_indexes/sih.taglibUris' # empty folder
handle_emptydir '/home/giovanni/custom/system/index/shared_indexes/sih.sql.types.count.index' # empty folder
handle_emptydir '/home/giovanni/custom/system/index/shared_indexes/sih.sql.routine.index' # empty folder
handle_emptydir '/home/giovanni/custom/system/index/shared_indexes/sih.spring.spiFileIndex' # empty folder
handle_emptydir '/home/giovanni/custom/system/index/shared_indexes/sih.spring.boot.importsFileIndex' # empty folder
handle_emptydir '/home/giovanni/custom/system/index/shared_indexes/sih.spring.autoConfigureMetadataIndex' # empty folder
handle_emptydir '/home/giovanni/custom/system/index/shared_indexes/sih.protoeditor.java.outer.class.index' # empty folder
handle_emptydir '/home/giovanni/custom/system/index/shared_indexes/sih.org.jetbrains.kotlin.idea.vfilefinder.KotlinStdlibIndex' # empty folder
handle_emptydir '/home/giovanni/custom/system/index/shared_indexes/sih.org.jetbrains.kotlin.idea.vfilefinder.KotlinShortClassNameFileIndex' # empty folder
handle_emptydir '/home/giovanni/custom/system/index/shared_indexes/sih.org.jetbrains.kotlin.idea.vfilefinder.KotlinPartialPackageNamesIndex' # empty folder
handle_emptydir '/home/giovanni/custom/system/index/shared_indexes/sih.org.jetbrains.kotlin.idea.vfilefinder.KotlinModuleMappingIndex' # empty folder
handle_emptydir '/home/giovanni/custom/system/index/shared_indexes/sih.org.jetbrains.kotlin.idea.vfilefinder.KotlinMetadataFilePackageIndex' # empty folder
handle_emptydir '/home/giovanni/custom/system/index/shared_indexes/sih.org.jetbrains.kotlin.idea.vfilefinder.KotlinMetadataFileIndex' # empty folder
handle_emptydir '/home/giovanni/custom/system/index/shared_indexes/sih.org.jetbrains.kotlin.idea.vfilefinder.KotlinJvmModuleAnnotationsIndex' # empty folder
handle_emptydir '/home/giovanni/custom/system/index/shared_indexes/sih.org.jetbrains.kotlin.idea.vfilefinder.KotlinJavaScriptMetaFileIndex' # empty folder
handle_emptydir '/home/giovanni/custom/system/index/shared_indexes/sih.org.jetbrains.kotlin.idea.vfilefinder.KotlinClassFileIndex' # empty folder
handle_emptydir '/home/giovanni/custom/system/index/shared_indexes/sih.org.jetbrains.kotlin.idea.vfilefinder.KotlinBuiltInsMetadataIndex' # empty folder
handle_emptydir '/home/giovanni/custom/system/index/shared_indexes/sih.org.jetbrains.kotlin.idea.vfilefinder.KlibMetaFileIndex' # empty folder
handle_emptydir '/home/giovanni/custom/system/index/shared_indexes/sih.org.jetbrains.kotlin.idea.versions.KotlinJvmMetadataVersionIndex' # empty folder
handle_emptydir '/home/giovanni/custom/system/index/shared_indexes/sih.org.jetbrains.kotlin.idea.versions.KotlinJsMetadataVersionIndex' # empty folder
handle_emptydir '/home/giovanni/custom/system/index/shared_indexes/sih.json.file.root.values' # empty folder
handle_emptydir '/home/giovanni/custom/system/index/shared_indexes/sih.js.package.index' # empty folder
handle_emptydir '/home/giovanni/custom/system/index/shared_indexes/sih.js.implicit.elements.index' # empty folder
handle_emptydir '/home/giovanni/custom/system/index/shared_indexes/sih.js.custom.single.entry.index' # empty folder
handle_emptydir '/home/giovanni/custom/system/index/shared_indexes/sih.javafx.stylesheets.name' # empty folder
handle_emptydir '/home/giovanni/custom/system/index/shared_indexes/sih.javafx.id.name' # empty folder
handle_emptydir '/home/giovanni/custom/system/index/shared_indexes/sih.javafx.custom.component' # empty folder
handle_emptydir '/home/giovanni/custom/system/index/shared_indexes/sih.java.source.module.name' # empty folder
handle_emptydir '/home/giovanni/custom/system/index/shared_indexes/sih.java.null.method.argument' # empty folder
handle_emptydir '/home/giovanni/custom/system/index/shared_indexes/sih.java.fun.expression' # empty folder
handle_emptydir '/home/giovanni/custom/system/index/shared_indexes/sih.java.binary.plus.expression' # empty folder
handle_emptydir '/home/giovanni/custom/system/index/shared_indexes/sih.http.request.name.index' # empty folder
handle_emptydir '/home/giovanni/custom/system/index/shared_indexes/sih.http.request.headers.values.index' # empty folder
handle_emptydir '/home/giovanni/custom/system/index/shared_indexes/sih.http.request.execution.environment' # empty folder
handle_emptydir '/home/giovanni/custom/system/index/shared_indexes/sih.http.request.completion.host' # empty folder
handle_emptydir '/home/giovanni/custom/system/index/shared_indexes/sih.html5.custom.attributes.index' # empty folder
handle_emptydir '/home/giovanni/custom/system/index/shared_indexes/sih.fileIncludes' # empty folder
handle_emptydir '/home/giovanni/custom/system/index/shared_indexes/sih.editorconfig.index.name' # empty folder
handle_emptydir '/home/giovanni/custom/system/index/shared_indexes/sih.css.template.selectors' # empty folder
handle_emptydir '/home/giovanni/custom/system/index/shared_indexes/sih.com.intellij.uiDesigner.FormClassIndex' # empty folder
handle_emptydir '/home/giovanni/custom/system/index/shared_indexes/sih.com.intellij.jpa.jpb.model.EntityRegisterFileIndex' # empty folder
handle_emptydir '/home/giovanni/custom/system/index/shared_indexes/sih.bytecodeAnalysis' # empty folder
handle_emptydir '/home/giovanni/custom/system/index/shared_indexes/sih.XsltSymbolIndex' # empty folder
handle_emptydir '/home/giovanni/custom/system/index/shared_indexes/sih.XmlTagNames' # empty folder
handle_emptydir '/home/giovanni/custom/system/index/shared_indexes/sih.WebComponentsIndex' # empty folder
handle_emptydir '/home/giovanni/custom/system/index/shared_indexes/sih.VueNoScriptFilesIndex' # empty folder
handle_emptydir '/home/giovanni/custom/system/index/shared_indexes/sih.VueComponentStylesIndex' # empty folder
handle_emptydir '/home/giovanni/custom/system/index/shared_indexes/sih.VtlFileIndex' # empty folder
handle_emptydir '/home/giovanni/custom/system/index/shared_indexes/sih.TypeScriptExternalPathCandidates' # empty folder
handle_emptydir '/home/giovanni/custom/system/index/shared_indexes/sih.TodoIndex' # empty folder
handle_emptydir '/home/giovanni/custom/system/index/shared_indexes/sih.SwReferencesIndex' # empty folder
handle_emptydir '/home/giovanni/custom/system/index/shared_indexes/sih.SpringXmlBeansIndex' # empty folder
handle_emptydir '/home/giovanni/custom/system/index/shared_indexes/sih.SchemaTypeInheritance' # empty folder
handle_emptydir '/home/giovanni/custom/system/index/shared_indexes/sih.OpenapiSpecificationContentIndexer' # empty folder
handle_emptydir '/home/giovanni/custom/system/index/shared_indexes/sih.LombokConfigIndex' # empty folder
handle_emptydir '/home/giovanni/custom/system/index/shared_indexes/sih.KotlinTopLevelClassLikeDeclarationByPackageShortNameIndex' # empty folder
handle_emptydir '/home/giovanni/custom/system/index/shared_indexes/sih.KotlinTopLevelCallableByPackageShortNameIndex' # empty folder
handle_emptydir '/home/giovanni/custom/system/index/shared_indexes/sih.KotlinPackageSourcesMemberNamesIndex' # empty folder
handle_emptydir '/home/giovanni/custom/system/index/shared_indexes/sih.KotlinBinaryRootToPackageIndex' # empty folder
handle_emptydir '/home/giovanni/custom/system/index/shared_indexes/sih.JavaFxControllerClassIndex' # empty folder
handle_emptydir '/home/giovanni/custom/system/index/shared_indexes/sih.HtmlTagIdIndex' # empty folder
handle_emptydir '/home/giovanni/custom/system/index/shared_indexes/sih.HtmlScriptSrcIndex' # empty folder
handle_emptydir '/home/giovanni/custom/system/index/shared_indexes/sih.HashFragmentIndex' # empty folder
handle_emptydir '/home/giovanni/custom/system/index/shared_indexes/sih.FtlFileIndex' # empty folder
handle_emptydir '/home/giovanni/custom/system/index/shared_indexes/sih.FrameworkDetectionIndex' # empty folder
handle_emptydir '/home/giovanni/custom/system/index/shared_indexes/sih.DomFileIndex' # empty folder
handle_emptydir '/home/giovanni/custom/system/index/shared_indexes/sih.CssIndex' # empty folder
handle_emptydir '/home/giovanni/custom/system/index/shared_indexes/sih.CompassFunctionsIndex' # empty folder
handle_emptydir '/home/giovanni/custom/system/full-line/models/0f001e7e-43ac-39af-8425-d94e491fb828/full-line-inference.zip_extracted' # empty folder
handle_emptydir '/home/giovanni/custom/system/frameworks/detection/progetto-se.c3023696' # empty folder
handle_emptydir '/home/giovanni/custom/system/frameworks/detection/progetto-se-2.1.0.22e424f4' # empty folder
handle_emptydir '/home/giovanni/custom/system/frameworks/detection/labor-services-exchange-dev.d4ef4cf3' # empty folder
handle_emptydir '/home/giovanni/custom/system/frameworks/detection/Matr735655_Matr735659_ArchivioCD.d8affe37' # empty folder
handle_emptydir '/home/giovanni/custom/system/frameworks/detection/FIX_PROGETTO.65ca5cca' # empty folder
handle_emptydir '/home/giovanni/custom/system/frameworks/detection/Ascensore.64d209a4' # empty folder
handle_emptydir '/home/giovanni/custom/system/compile-server/progetto-se_dbd5ab6c/targets/resources-test/progetto-se_ad651efb/src-out' # empty folder
handle_emptydir '/home/giovanni/custom/system/compile-server/progetto-se_dbd5ab6c/targets/resources-production/progetto-se_ad651efb/src-out' # empty folder
handle_emptydir '/home/giovanni/custom/system/compile-server/progetto-se_dbd5ab6c/targets/resources-production/progetto-se_ad651efb' # empty folder
handle_emptydir '/home/giovanni/custom/system/compile-server/progetto-se_dbd5ab6c/targets/project-dependencies-resolving' # empty folder
handle_emptydir '/home/giovanni/custom/system/compile-server/progetto-se_dbd5ab6c/targets/maven-resources-test/progetto-se_ad651efb/src-out' # empty folder
handle_emptydir '/home/giovanni/custom/system/compile-server/progetto-se_dbd5ab6c/targets/maven-resources-production/progetto-se_ad651efb/src-out' # empty folder
handle_emptydir '/home/giovanni/custom/system/compile-server/progetto-se_dbd5ab6c/targets/maven-annotations-test/progetto-se_ad651efb/src-out' # empty folder
handle_emptydir '/home/giovanni/custom/system/compile-server/progetto-se_dbd5ab6c/targets/maven-annotations-test/progetto-se_ad651efb' # empty folder
handle_emptydir '/home/giovanni/custom/system/compile-server/progetto-se_dbd5ab6c/targets/maven-annotations-production/progetto-se_ad651efb/src-out' # empty folder
handle_emptydir '/home/giovanni/custom/system/compile-server/progetto-se_dbd5ab6c/targets/maven-annotations-production/progetto-se_ad651efb' # empty folder
handle_emptydir '/home/giovanni/custom/system/compile-server/progetto-se_dbd5ab6c/targets/java-test/progetto-se_ad651efb/src-out' # empty folder
handle_emptydir '/home/giovanni/custom/system/compile-server/progetto-se_dbd5ab6c/targets/java-test/progetto-se_ad651efb/kotlin' # empty folder
handle_emptydir '/home/giovanni/custom/system/compile-server/progetto-se_dbd5ab6c/targets/java-production/progetto-se_ad651efb/kotlin' # empty folder
handle_emptydir '/home/giovanni/custom/system/compile-server/progetto-se_dbd5ab6c/targets/groovy-check-resources_tests' # empty folder
handle_emptydir '/home/giovanni/custom/system/compile-server/progetto-se_dbd5ab6c/targets/groovy-check-resources' # empty folder
handle_emptydir '/home/giovanni/custom/system/compile-server/progetto-se_dbd5ab6c/src-form' # empty folder
handle_emptydir '/home/giovanni/custom/system/compile-server/progetto-se-2_1_0_8696db4a/targets/resources-test/progetto-se_ad651efb/src-out' # empty folder
handle_emptydir '/home/giovanni/custom/system/compile-server/progetto-se-2_1_0_8696db4a/targets/resources-production/progetto-se_ad651efb/src-out' # empty folder
handle_emptydir '/home/giovanni/custom/system/compile-server/progetto-se-2_1_0_8696db4a/targets/project-dependencies-resolving' # empty folder
handle_emptydir '/home/giovanni/custom/system/compile-server/progetto-se-2_1_0_8696db4a/targets/maven-resources-test/progetto-se_ad651efb/src-out' # empty folder
handle_emptydir '/home/giovanni/custom/system/compile-server/progetto-se-2_1_0_8696db4a/targets/maven-resources-production/progetto-se_ad651efb/src-out' # empty folder
handle_emptydir '/home/giovanni/custom/system/compile-server/progetto-se-2_1_0_8696db4a/targets/maven-annotations-test/progetto-se_ad651efb/src-out' # empty folder
handle_emptydir '/home/giovanni/custom/system/compile-server/progetto-se-2_1_0_8696db4a/targets/maven-annotations-test/progetto-se_ad651efb' # empty folder
handle_emptydir '/home/giovanni/custom/system/compile-server/progetto-se-2_1_0_8696db4a/targets/maven-annotations-production/progetto-se_ad651efb/src-out' # empty folder
handle_emptydir '/home/giovanni/custom/system/compile-server/progetto-se-2_1_0_8696db4a/targets/maven-annotations-production/progetto-se_ad651efb' # empty folder
handle_emptydir '/home/giovanni/custom/system/compile-server/progetto-se-2_1_0_8696db4a/targets/jsp-validation' # empty folder
handle_emptydir '/home/giovanni/custom/system/compile-server/progetto-se-2_1_0_8696db4a/targets/java-test/progetto-se_ad651efb/src-out' # empty folder
handle_emptydir '/home/giovanni/custom/system/compile-server/progetto-se-2_1_0_8696db4a/targets/groovy-check-resources_tests' # empty folder
handle_emptydir '/home/giovanni/custom/system/compile-server/progetto-se-2_1_0_8696db4a/targets/groovy-check-resources' # empty folder
handle_emptydir '/home/giovanni/custom/system/compile-server/progetto-se-2_1_0_8696db4a/targets/gradle-resources-production' # empty folder
handle_emptydir '/home/giovanni/custom/system/compile-server/progetto-se-2_1_0_8696db4a/src-form' # empty folder
handle_emptydir '/home/giovanni/custom/system/Maven/Projects/f80747ce' # empty folder
handle_emptydir '/home/giovanni/custom/system/Maven/Projects/Default (Template) Project' # empty folder
handle_emptydir '/home/giovanni/custom/system/Maven/Projects/65ca5cca' # empty folder
handle_emptydir '/home/giovanni/custom/system/Maven/Projects/64d209a4' # empty folder
handle_emptydir '/home/giovanni/custom/config/event-log-metadata/mp' # empty folder
handle_emptydir '/home/giovanni/custom/config/event-log-metadata/fus' # empty folder
handle_emptydir '/home/giovanni/Vaults/obsidian-nepero/CIRCUITI ED ELETTRONICA/SED/imgs' # empty folder
handle_emptydir '/home/giovanni/Vaults/obsidian-nepero/CIRCUITI ED ELETTRONICA/SED/file 6/appunti da lezione' # empty folder
handle_emptydir '/home/giovanni/Vaults/obsidian-nepero/CIRCUITI ED ELETTRONICA/SED/file 5/timing' # empty folder
handle_emptydir '/home/giovanni/Vaults/obsidian-nepero/CIRCUITI ED ELETTRONICA/SED/file 4/Sequenziali/memorie' # empty folder
handle_emptydir '/home/giovanni/Vaults/obsidian-nepero/CIRCUITI ED ELETTRONICA/FE/misc definitions' # empty folder
handle_emptydir '/home/giovanni/Vaults/obsidian-nepero/CIRCUITI ED ELETTRONICA/FE/file 5/famiglie logiche' # empty folder
handle_emptydir '/home/giovanni/Vaults/obsidian-nepero/CIRCUITI ED ELETTRONICA/FE/file 2' # empty folder
handle_emptydir '/home/giovanni/Vaults/obsidian-nepero/CIRCUITI ED ELETTRONICA/FE/file 1/fasori' # empty folder
handle_emptydir '/home/giovanni/Vaults/obsidian-nepero/CIRCUITI ED ELETTRONICA/FE/file 1/circuiti dinamici' # empty folder
handle_emptydir '/home/giovanni/Vaults/obsidian-nepero/CIRCUITI ED ELETTRONICA/FE/esercizi' # empty folder
handle_emptydir '/home/giovanni/Vaults/nepero-studia/Elettronica Generale/EG - Obsidian/SED/file 6/dispositivi' # empty folder
handle_emptydir '/home/giovanni/Vaults/nepero-studia/Elettronica Generale/EG - Obsidian/SED/file 6/appunti da lezione' # empty folder
handle_emptydir '/home/giovanni/Vaults/nepero-studia/Elettronica Generale/EG - Obsidian/SED/file 4/Combinatori' # empty folder
handle_emptydir '/home/giovanni/Vaults/nepero-studia/Elettronica Generale/EG - Obsidian/SED/file 3' # empty folder
handle_emptydir '/home/giovanni/Vaults/nepero-studia/Elettronica Generale/EG - Obsidian/SED/file 2' # empty folder
handle_emptydir '/home/giovanni/Vaults/nepero-studia/Elettronica Generale/EG - Obsidian/SED/file 1' # empty folder
handle_emptydir '/home/giovanni/Vaults/nepero-studia/Elettronica Generale/EG - Obsidian/SED/esercizi' # empty folder
handle_emptydir '/home/giovanni/Vaults/grotta-di-nepero/06 - ARCHIVES/AUTOMATICA/appunti extra/APPUNTI E TE AUTOMATICA/svolti/Temi d_esame per MECLT e GESLM (pre 2001)x' # empty folder
handle_emptydir '/home/giovanni/Vaults/grotta-di-nepero/06 - ARCHIVES/AUTOMATICA/appunti extra/APPUNTI E TE AUTOMATICA/svolti/Altri temi d_esamex' # empty folder
handle_emptydir '/home/giovanni/Vaults/grotta-di-nepero/06 - ARCHIVES/AUTOMATICA/appunti extra/APPUNTI E TE AUTOMATICA/svolti/19Aprile2011_Svoltox' # empty folder
handle_emptydir '/home/giovanni/Vaults/grotta-di-nepero/06 - ARCHIVES/AUTOMATICA/appunti extra/APPUNTI E TE AUTOMATICA/svolti/14Settembre2010_Svoltox' # empty folder
handle_emptydir '/home/giovanni/Vaults/grotta-di-nepero/06 - ARCHIVES/AUTOMATICA/appunti extra/APPUNTI E TE AUTOMATICA/svolti' # empty folder
handle_emptydir '/home/giovanni/Vaults/grotta-di-nepero/06 - ARCHIVES/AUTOMATICA/appunti extra/APPUNTI E TE AUTOMATICA' # empty folder
handle_emptydir '/home/giovanni/Vaults/grotta-di-nepero/06 - ARCHIVES/AUTOMATICA/appunti extra' # empty folder
handle_emptydir '/home/giovanni/Universita/Materiale Didattico/old exams/fisica II/sec parz/esercizi lezione 31_03_23' # empty folder
handle_emptydir '/home/giovanni/Tools/idea-IU-241.17890.1/plugins/textmate/lib/bundles/twig/src/snippets' # empty folder
handle_emptydir '/home/giovanni/Tools/idea-IU-241.17890.1/plugins/textmate/lib/bundles/powershell/snippets' # empty folder
handle_emptydir '/home/giovanni/Tools/idea-IU-241.17890.1/jbr/legal/jdk.zipfs' # empty folder
handle_emptydir '/home/giovanni/Tools/idea-IU-241.17890.1/jbr/legal/jdk.xml.dom' # empty folder
handle_emptydir '/home/giovanni/Tools/idea-IU-241.17890.1/jbr/legal/jdk.unsupported.desktop' # empty folder
handle_emptydir '/home/giovanni/Tools/idea-IU-241.17890.1/jbr/legal/jdk.unsupported' # empty folder
handle_emptydir '/home/giovanni/Tools/idea-IU-241.17890.1/jbr/legal/jdk.security.auth' # empty folder
handle_emptydir '/home/giovanni/Tools/idea-IU-241.17890.1/jbr/legal/jdk.sctp' # empty folder
handle_emptydir '/home/giovanni/Tools/idea-IU-241.17890.1/jbr/legal/jdk.net' # empty folder
handle_emptydir '/home/giovanni/Tools/idea-IU-241.17890.1/jbr/legal/jdk.naming.rmi' # empty folder
handle_emptydir '/home/giovanni/Tools/idea-IU-241.17890.1/jbr/legal/jdk.naming.dns' # empty folder
handle_emptydir '/home/giovanni/Tools/idea-IU-241.17890.1/jbr/legal/jdk.management.jfr' # empty folder
handle_emptydir '/home/giovanni/Tools/idea-IU-241.17890.1/jbr/legal/jdk.management.agent' # empty folder
handle_emptydir '/home/giovanni/Tools/idea-IU-241.17890.1/jbr/legal/jdk.management' # empty folder
handle_emptydir '/home/giovanni/Tools/idea-IU-241.17890.1/jbr/legal/jdk.jsobject' # empty folder
handle_emptydir '/home/giovanni/Tools/idea-IU-241.17890.1/jbr/legal/jdk.jfr' # empty folder
handle_emptydir '/home/giovanni/Tools/idea-IU-241.17890.1/jbr/legal/jdk.jdwp.agent' # empty folder
handle_emptydir '/home/giovanni/Tools/idea-IU-241.17890.1/jbr/legal/jdk.jdi' # empty folder
handle_emptydir '/home/giovanni/Tools/idea-IU-241.17890.1/jbr/legal/jdk.jcmd' # empty folder
handle_emptydir '/home/giovanni/Tools/idea-IU-241.17890.1/jbr/legal/jdk.internal.vm.ci' # empty folder
handle_emptydir '/home/giovanni/Tools/idea-IU-241.17890.1/jbr/legal/jdk.internal.jvmstat' # empty folder
handle_emptydir '/home/giovanni/Tools/idea-IU-241.17890.1/jbr/legal/jdk.internal.ed' # empty folder
handle_emptydir '/home/giovanni/Tools/idea-IU-241.17890.1/jbr/legal/jdk.httpserver' # empty folder
handle_emptydir '/home/giovanni/Tools/idea-IU-241.17890.1/jbr/legal/jdk.hotspot.agent' # empty folder
handle_emptydir '/home/giovanni/Tools/idea-IU-241.17890.1/jbr/legal/jdk.crypto.ec' # empty folder
handle_emptydir '/home/giovanni/Tools/idea-IU-241.17890.1/jbr/legal/jdk.compiler' # empty folder
handle_emptydir '/home/giovanni/Tools/idea-IU-241.17890.1/jbr/legal/jdk.charsets' # empty folder
handle_emptydir '/home/giovanni/Tools/idea-IU-241.17890.1/jbr/legal/jdk.attach' # empty folder
handle_emptydir '/home/giovanni/Tools/idea-IU-241.17890.1/jbr/legal/jdk.accessibility' # empty folder
handle_emptydir '/home/giovanni/Tools/idea-IU-241.17890.1/jbr/legal/java.transaction.xa' # empty folder
handle_emptydir '/home/giovanni/Tools/idea-IU-241.17890.1/jbr/legal/java.sql.rowset' # empty folder
handle_emptydir '/home/giovanni/Tools/idea-IU-241.17890.1/jbr/legal/java.sql' # empty folder
handle_emptydir '/home/giovanni/Tools/idea-IU-241.17890.1/jbr/legal/java.security.sasl' # empty folder
handle_emptydir '/home/giovanni/Tools/idea-IU-241.17890.1/jbr/legal/java.security.jgss' # empty folder
handle_emptydir '/home/giovanni/Tools/idea-IU-241.17890.1/jbr/legal/java.se' # empty folder
handle_emptydir '/home/giovanni/Tools/idea-IU-241.17890.1/jbr/legal/java.scripting' # empty folder
handle_emptydir '/home/giovanni/Tools/idea-IU-241.17890.1/jbr/legal/java.rmi' # empty folder
handle_emptydir '/home/giovanni/Tools/idea-IU-241.17890.1/jbr/legal/java.prefs' # empty folder
handle_emptydir '/home/giovanni/Tools/idea-IU-241.17890.1/jbr/legal/java.net.http' # empty folder
handle_emptydir '/home/giovanni/Tools/idea-IU-241.17890.1/jbr/legal/java.naming' # empty folder
handle_emptydir '/home/giovanni/Tools/idea-IU-241.17890.1/jbr/legal/java.management.rmi' # empty folder
handle_emptydir '/home/giovanni/Tools/idea-IU-241.17890.1/jbr/legal/java.management' # empty folder
handle_emptydir '/home/giovanni/Tools/idea-IU-241.17890.1/jbr/legal/java.logging' # empty folder
handle_emptydir '/home/giovanni/Tools/idea-IU-241.17890.1/jbr/legal/java.instrument' # empty folder
handle_emptydir '/home/giovanni/Tools/idea-IU-241.17890.1/jbr/legal/java.datatransfer' # empty folder
handle_emptydir '/home/giovanni/Tools/idea-IU-241.17890.1/jbr/legal/java.compiler' # empty folder
handle_emptydir '/home/giovanni/Documenti Neperiani/poco backup/Download/browser_m3u' # empty folder
handle_emptydir '/home/giovanni/Documenti Neperiani/Sistema Sanitario Neperiano/carte endocrinologo/referti visite/referti ormoni' # empty folder
handle_emptydir '/home/giovanni/Documenti Neperiani/Sistema Sanitario Neperiano/carte endocrinologo/referti visite/referti mutazioni' # empty folder
handle_emptydir '/home/giovanni/Code/progetto-se/out/artifacts/Ermes_v4_1' # empty folder
handle_emptydir '/home/giovanni/Code/progetto-se/META-INF' # empty folder
handle_emptydir '/home/giovanni/Code/java/eclipse-workspace/Matr735655_Matr735659_ArchivioCD/Matr735655_Matr735659_ArchivioCD/doc/script-dir/images' # empty folder
handle_emptydir '/home/giovanni/Code/java/eclipse-workspace/Matr735655_Matr735659_ArchivioCD/Matr735655_Matr735659_ArchivioCD/doc/script-dir' # empty folder
handle_emptydir '/home/giovanni/Code/java/eclipse-workspace/Matr735655_Matr735659_ArchivioCD/Matr735655_Matr735659_ArchivioCD/doc/resources' # empty folder
handle_emptydir '/home/giovanni/Code/java/eclipse-workspace/Matr735655_Matr735659_ArchivioCD/Matr735655_Matr735659_ArchivioCD/doc/legal' # empty folder
handle_emptydir '/home/giovanni/Code/java/eclipse-workspace/Graphics/out/production/Graphics/com/intellij/uiDesigner/core' # empty folder
handle_emptydir '/home/giovanni/Code/java/eclipse-workspace/Graphics/out/production/Graphics/com/intellij/uiDesigner' # empty folder
handle_emptydir '/home/giovanni/Code/java/eclipse-workspace/Graphics/out/production/Graphics/com/intellij' # empty folder
handle_emptydir '/home/giovanni/Code/java/eclipse-workspace/Graphics/out/production/Graphics/com' # empty folder
handle_emptydir '/home/giovanni/Code/FIX_PROGETTO/FIX_PROGETTO/src' # empty folder

original_cmd  '/home/giovanni/Download/FAC SIMILE SEGNALAZIONI DICATAM 2024.docx.pdf' # original
remove_cmd    '/home/giovanni/Download/SEGNALAZIONI PARITETICA DICATAM 2024.pdf' '/home/giovanni/Download/FAC SIMILE SEGNALAZIONI DICATAM 2024.docx.pdf' # duplicate
                                               
                                               
                                               
######### END OF AUTOGENERATED OUTPUT #########
                                               
if [ $PROGRESS_CURR -le $PROGRESS_TOTAL ]; then
    print_progress_prefix                      
    echo "${COL_BLUE}Done!${COL_RESET}"      
fi                                             
                                               
if [ -z $DO_REMOVE ] && [ -z $DO_DRY_RUN ]     
then                                           
  echo "Deleting script " "$0"             
  rm -f '/home/giovanni/.local/bin/rmlint.sh';                                     
fi                                             
