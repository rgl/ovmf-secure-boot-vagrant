#!/bin/bash
set -eu -o pipefail -o errtrace


function title {
    cat <<EOF

########################################################################
#
# $*
#

EOF
}


set -x
