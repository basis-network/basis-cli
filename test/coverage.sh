#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2026 Basis Network
# SPDX-License-Identifier: Apache-2.0
# ---------------------------------------------------------------------------
# Statement coverage for `download.sh`.
#
#     make coverage                       or            test/coverage.sh
#     COVERAGE_MINIMUM=95 make coverage   to demand more than the default
#
# Needs bashcov, which needs Ruby:
#
#     gem install bashcov
#
# Why this file exists rather than a one-line bashcov invocation: the suite
# runs `download.sh` from a throwaway sandbox and deletes the sandbox when the
# case ends, so by the time bashcov writes its report the file it traced is
# gone and nothing can be attributed to it. Two things follow.
#
#   1. `BASIS_TEST_KEEP` tells the suite to leave its sandboxes alone.
#   2. `TMPDIR` is pointed inside the tree, because SimpleCov ignores paths
#      with a dot-prefixed component and will silently drop everything under a
#      hidden directory -- no error, just a report that says 0%.
#
# Every case gets its own copy of the same bytes, so the copies are summed per
# line: line N is covered if any case reached it. That is what "the suite
# covers this line" means, and no single sandbox can answer it alone.
#
# One line is reported uncovered and is not: the `done` that closes the
# download loop carries the redirection, and bash attributes the redirection to
# the `while` instead. Every case that downloads anything runs it. It is left
# in the report rather than special-cased, because a coverage tool that is
# taught to lie about one line is no longer evidence about the others.
# ---------------------------------------------------------------------------
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root="$(cd "$here/.." && pwd)"

# 90 is the OpenSSF Best Practices gold threshold; silver asks for 80. The
# default is the higher one so a regression is caught where it happens rather
# than the next time someone reads the badge.
minimum="${COVERAGE_MINIMUM:-90}"

command -v bashcov >/dev/null 2>&1 || {
  echo "  x bashcov not found -- install it with: gem install bashcov" >&2
  exit 2
}

cd "$root"
rm -rf coverage covtmp
mkdir -p covtmp

BASIS_TEST_KEEP=1 TMPDIR="$root/covtmp" bashcov -- ./test/run.sh

[ -f coverage/.resultset.json ] || {
  echo "  x bashcov wrote no resultset" >&2
  exit 1
}

ruby -rjson -e '
  minimum = Float(ARGV[0])
  data    = JSON.parse(File.read("coverage/.resultset.json"))
  source  = File.readlines("download.sh")

  # Sum the sandbox copies line by line. nil means "not a statement" and stays
  # nil; anything else is a hit count and adds up.
  union = nil
  data.each_value do |run|
    (run["coverage"] || {}).each do |path, entry|
      next unless path.end_with?("/download.sh")
      lines = entry.is_a?(Hash) ? entry["lines"] : entry
      if union.nil?
        union = lines.dup
      else
        lines.each_with_index do |hits, i|
          next if hits.nil?
          union[i] = union[i].nil? ? hits : union[i] + hits
        end
      end
    end
  end

  abort("  x download.sh was never traced -- did the suite run?") if union.nil?

  statements = union.compact
  covered    = statements.count { |hits| hits.to_i > 0 }
  percent    = 100.0 * covered / statements.size

  missed = union.each_with_index.reject { |hits, _| hits.nil? || hits.to_i > 0 }
  unless missed.empty?
    puts
    puts "not covered:"
    missed.each { |_, i| puts format("  %3d  %s", i + 1, source[i].to_s.rstrip) }
  end

  puts
  puts format("download.sh: %d/%d statements, %.1f%% (minimum %.0f%%)",
              covered, statements.size, percent, minimum)
  exit(percent + 1e-9 >= minimum ? 0 : 1)
' "$minimum"
