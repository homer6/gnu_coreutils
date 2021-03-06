#!/bin/sh
# Show that --color need not use stat, as long as we have d_type support.

# Copyright (C) 2011-2012 Free Software Foundation, Inc.

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

. "${srcdir=.}/tests/init.sh"; path_prepend_ ./src
print_ver_ ls
require_strace_ stat
require_dirent_d_type_

for i in 1 2 3; do
  ln -s nowhere dangle-$i || framework_failure_
done

# Disable enough features via LS_COLORS so that ls --color
# can do its job without calling stat (other than the obligatory
# one-call-per-command-line argument).
cat <<EOF > color-without-stat || framework_failure_
RESET 0
DIR 01;34
LINK 01;36
FIFO 40;33
SOCK 01;35
DOOR 01;35
BLK 40;33;01
CHR 40;33;01
ORPHAN 00
SETUID 00
SETGID 00
CAPABILITY 00
STICKY_OTHER_WRITABLE 00
OTHER_WRITABLE 00
STICKY 00
EXEC 00
MULTIHARDLINK 00
EOF
eval $(dircolors -b color-without-stat)

# The system may perform additional stat-like calls before main.
# To avoid counting those, first get a baseline count by running
# ls with only the --help option.  Then, compare that with the
# invocation under test.
strace -o log-help -e stat,lstat,stat64,lstat64 ls --help >/dev/null || fail=1
n_lines_help=$(wc -l < log-help)

strace -o log -e stat,lstat,stat64,lstat64 ls --color=always . || fail=1
n_lines=$(wc -l < log)

n_stat=$(expr $n_lines - $n_lines_help)

# Expect one or two stat calls.
case $n_stat in
  1) ;;
  *) fail=1; head -n30 log* ;;
esac

Exit $fail
