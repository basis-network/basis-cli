# SPDX-FileCopyrightText: 2026 Basis Network
# SPDX-License-Identifier: Apache-2.0
#
# There is nothing to build here. The CLI binary comes from a GitHub release,
# not from this tree, and `download.sh` is read by an interpreter as it is.
# What there is to do is check, and these are the two things CI runs.

.PHONY: all check lint

all: check

# The test suite for download.sh. Needs nothing download.sh does not.
check:
	@test/run.sh

# Both scripts through shellcheck, and every file through reuse.
lint:
	shellcheck download.sh test/run.sh
	reuse lint
