#!/usr/bin/env ruby
# frozen_string_literal: true

# Regenerate site.min.css from site.css using clean-css-cli (via npx).
# Requires Node.js. Run from repo root: ruby scripts/minify_css.rb
#
# Edit site.css (source of truth), then run this before commit so site.min.css stays in sync.

require "fileutils"

ROOT = File.expand_path("..", __dir__)
Dir.chdir(ROOT) || abort("chdir #{ROOT} failed")

status = system(
  "npx", "--yes", "clean-css-cli@5.6.2", "-O1", "site.css", "-o", "site.min.css"
)
abort "minify_css: clean-css failed (install Node.js?)" unless status

min_path = File.join(ROOT, "site.min.css")
puts "Wrote #{min_path} (#{File.size(min_path)} bytes)"
