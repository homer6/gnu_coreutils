#!/bin/sh
# Ensure that tail does not ignore data that is appended to a tailed-forever
# file between tail's initial read-to-EOF, and when the inotify watches
# are established in tail_forever_inotify.  That data could be ignored
# indefinitely if no *other* data is appended, but it would be printed as
# soon as any additional appended data is detected.

# Copyright (C) 2009-2012 Free Software Foundation, Inc.

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
print_ver_ tail

# Don't run this test by default because sometimes it's skipped as noted below.
# Also gdb has a bug in Debian's gdb-6.8-3 at least that causes it to not
# cleanup and exit correctly when it receives a SIGTERM, thus hanging the test.
very_expensive_

touch file || framework_failure_
touch tail.out || framework_failure_

( timeout 10s gdb --version ) > gdb.out 2>&1
case $(cat gdb.out) in
    *'GNU gdb'*) ;;
    *) skip_ "can't run gdb";;
esac

# See if gdb works and
# tail_forever_inotify is compiled and not inlined
timeout 10s gdb -nx --batch-silent                 \
    --eval-command='break tail_forever_inotify'    \
    --eval-command='run -f file'                   \
    --eval-command='quit'                          \
    tail < /dev/null > gdb.out 2>&1

# FIXME: The above is seen to _intermittently_ fail with:
# warning: .dynamic section for "/lib/libc.so.6" is not at the expected address
# warning: difference appears to be caused by prelink, adjusting expectations
test -s gdb.out && { cat gdb.out; skip_ "can't set breakpoints in tail"; }

# Run "tail -f file", stopping to append a line just before
# inotify initialization, and then continue.  Before the fix,
# that just-appended line would never be output.
timeout 10s gdb -nx --batch-silent                 \
    --eval-command='break tail_forever_inotify'    \
    --eval-command='run -f file >> tail.out'       \
    --eval-command="shell echo never-seen-with-tail-7.5 >> file" \
    --eval-command='continue'                      \
    --eval-command='quit'                          \
    tail < /dev/null > /dev/null 2>&1 &
pid=$!

tail --pid=$pid -f tail.out | (read; kill $pid)

test -s tail.out || fail=1

Exit $fail
