#!/bin/sh
# move a file onto itself

# Copyright (C) 1999-2012 Free Software Foundation, Inc.

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
print_ver_ mv

ff=mvforce
ff2=mvforce2

echo force-contents > $ff || framework_failure_
ln $ff $ff2 || framework_failure_

# This mv command should exit nonzero.
mv $ff $ff > out 2>&1 && fail=1

cat > exp <<EOF
mv: '$ff' and '$ff' are the same file
EOF

compare exp out || fail=1
test $(cat $ff) = force-contents || fail=1

# This should succeed, even though the source and destination
# device and inodes are the same.
mv $ff $ff2 || fail=1

Exit $fail
