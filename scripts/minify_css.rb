#!/usr/bin/env ruby
# frozen_string_literal: true

# Regenerate site.min.css from site.css using clean-css-cli from local node_modules.
# Run `npm install` once from repo root, then: ruby scripts/minify_css.rb
#
# Edit site.css (source of truth), then run this before commit so site.min.css stays in sync.

require "fileutils"

ROOT = File.expand_path("..", __dir__)
Dir.chdir(ROOT) || abort("chdir #{ROOT} failed")

cleancss = File.join(ROOT, "node_modules", "clean-css-cli", "bin", "cleancss")
unless File.exist?(cleancss)
  warn "minify_css: missing #{cleancss}. Run `npm install` from the repo root first."
  abort
end

status = system("node", cleancss, "-O1", "site.css", "-o", "site.min.css")
abort "minify_css: clean-css failed" unless status

min_path = File.join(ROOT, "site.min.css")
puts "Wrote #{min_path} (#{File.size(min_path)} bytes)"
