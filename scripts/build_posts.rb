#!/usr/bin/env ruby
# frozen_string_literal: true

require "cgi"
require "date"
require "fileutils"

ROOT = File.expand_path("..", __dir__)
SITE_ORIGIN = "https://www.nickraushenbush.com"
OG_IMAGE_URL = "#{SITE_ORIGIN}/assets/og-image.png?v=20260402-assets"
# Bump when theme scripts change (cache bust).
THEME_ASSET_VERSION = "20260402-assets"
FAVICON_QUERY = "20260402-assets"
SITE_CSS_QUERY = "20260331-security"
CONTENT_SECURITY_POLICY = "default-src 'self'; script-src 'self'; style-src 'self'; " \
  "img-src 'self' data:; font-src 'self'; connect-src 'self'; object-src 'none'; " \
  "base-uri 'self'; upgrade-insecure-requests"
SOURCE_DIR = File.join(ROOT, "sources")
BLOG_DIR = File.join(ROOT, "blog")
INDEX_PATH = File.join(ROOT, "index.html")

POST_LIST_START = "<!-- POST_LIST_START -->"
POST_LIST_END = "<!-- POST_LIST_END -->"

def html_escape(text)
  CGI.escapeHTML(text)
end

MAX_LINK_HREF_LENGTH = 2048

# Only allow http(s), mailto:, or same-site relative paths (no javascript:/data:/etc.).
def link_href_attributes(href)
  h = href.strip
  return [nil, false] if h.empty? || h.length > MAX_LINK_HREF_LENGTH
  return [nil, false] if h.start_with?("//")

  esc = CGI.escapeHTML(href)
  if h.match?(%r{\Ahttps?://}i)
    return [%( href="#{esc}" target="_blank" rel="noopener noreferrer"), true]
  end
  if h.match?(%r{\Amailto:}i)
    return [%( href="#{esc}"), true]
  end
  return [nil, false] if h.include?(":")
  return [nil, false] unless h.match?(%r{\A[A-Za-z0-9_./#?=&%+\-]+\z})

  [%( href="#{esc}"), true]
end

def inline(text)
  escaped = html_escape(text)
  escaped.gsub!(%r{\[([^\]]+)\]\(([^)]+)\)}) do
    label = Regexp.last_match(1)
    href = Regexp.last_match(2)
    attrs, ok = link_href_attributes(href)
    if ok
      %(<a#{attrs}>#{inline(label)}</a>)
    else
      %(<span class="inline-link-unsupported">#{inline(label)}</span>)
    end
  end
  escaped.gsub!(/\*\*\*(.+?)\*\*\*/) { "<strong><em>#{$1}</em></strong>" }
  escaped.gsub!(/\*\*(.+?)\*\*/) { "<strong>#{$1}</strong>" }
  escaped.gsub!(/(?<!\*)\*([^*]+)\*(?!\*)/) { "<em>#{$1}</em>" }
  escaped
end

def plain_text(text)
  text.gsub(/\[([^\]]+)\]\(([^)]+)\)/, '\1').gsub(/[*_`>#-]/, "").strip
end

def slug_for(path)
  "#{File.basename(path, ".md")}.html"
end

def parse_date(byline)
  byline[/—\s*(.+?)\*$/, 1]&.strip || ""
end

# Optional split in the # title line: use " || " between two segments. The
# first segment is wrapped in .post-title-line (nowrap) so it stays on one line;
# meta tags and the homepage list use the segments joined with a single space.
TITLE_HEADING_SPLIT = /\s\|\|\s/

def parse_title_from_heading(title_line)
  raw = title_line.sub(/^#\s+/, "").strip
  if raw.match?(TITLE_HEADING_SPLIT)
    first, second = raw.split(TITLE_HEADING_SPLIT, 2).map(&:strip)
    title = "#{first} #{second}"
    title_h1_html = %(<span class="post-title-line">#{html_escape(first)}</span> #{html_escape(second)})
    [title, title_h1_html]
  else
    [raw, html_escape(raw)]
  end
end

def sort_time_for_date_string(date_str)
  return Time.at(0) if date_str.nil? || date_str.strip.empty?

  Date.parse(date_str).to_time
rescue ArgumentError
  Time.at(0)
end

def consume_paragraph(lines, start_index)
  parts = []
  index = start_index
  while index < lines.length
    line = lines[index]
    break if line.strip.empty?
    break if line.start_with?("#", ">", "-", "* ")
    break if line.match?(/^\d+\.\s+/)
    break if line.strip == "---"

    parts << line.strip
    index += 1
  end
  [parts.join(" "), index]
end

def consume_list(lines, start_index)
  ordered = lines[start_index].match?(/^\d+\.\s+/)
  tag = ordered ? "ol" : "ul"
  items = []
  index = start_index

  while index < lines.length
    line = lines[index]
    pattern = ordered ? /^\d+\.\s+/ : /^[-*]\s+/
    break unless line.match?(pattern)

    item = line.sub(pattern, "").strip
    index += 1
    while index < lines.length
      continuation = lines[index]
      break if continuation.strip.empty?
      break if continuation.match?(pattern)
      break if ordered && continuation.match?(/^\d+\.\s+/)
      break if continuation.start_with?("#", ">") || continuation.strip == "---"

      item = "#{item} #{continuation.strip}"
      index += 1
    end
    items << "            <li>#{inline(item)}</li>"
  end

  ["          <#{tag}>\n#{items.join("\n")}\n          </#{tag}>", index]
end

def consume_blockquote(lines, start_index)
  parts = []
  index = start_index
  while index < lines.length
    line = lines[index]
    break unless line.start_with?(">")

    stripped = line.sub(/^>\s?/, "").strip
    if stripped.empty?
      parts << "\n\n"
    else
      parts << stripped
      parts << " "
    end
    index += 1
  end

  text = parts.join.strip.gsub(/\s+\n\n\s+/, "\n\n")
  paras = text.split(/\n{2,}/).map { |p| "            #{inline(p.strip)}" }
  ["          <blockquote>\n#{paras.join("\n\n")}\n          </blockquote>", index]
end

def render_body(lines)
  body = []
  index = 0
  while index < lines.length
    line = lines[index]
    stripped = line.strip

    if stripped.empty? || stripped == "---"
      index += 1
      next
    end

    case line
    when /^####\s+(.*)/
      body << "          <h4>#{inline(Regexp.last_match(1).strip)}</h4>"
      index += 1
    when /^###\s+(.*)/
      body << "          <h3>#{inline(Regexp.last_match(1).strip)}</h3>"
      index += 1
    when /^##\s+(.*)/
      body << "          <h2>#{inline(Regexp.last_match(1).strip)}</h2>"
      index += 1
    when /^>\s?.*/
      blockquote, index = consume_blockquote(lines, index)
      body << blockquote
    when /^[-*]\s+/, /^\d+\.\s+/
      list, index = consume_list(lines, index)
      body << list
    else
      paragraph, index = consume_paragraph(lines, index)
      body << "          <p>#{inline(paragraph)}</p>" unless paragraph.empty?
    end
  end
  body.join("\n\n")
end

def parse_source(source_path)
  raw_lines = File.readlines(source_path, chomp: true)
  title_line = raw_lines.shift
  raise "Missing title in #{source_path}" unless title_line&.start_with?("# ")

  title, title_h1_html = parse_title_from_heading(title_line)
  raw_lines.shift while raw_lines.first&.strip == ""
  byline = raw_lines.shift.to_s.strip
  date = parse_date(byline)
  raw_lines.shift while raw_lines.first&.strip == ""

  description_source = raw_lines.find { |line| !line.strip.empty? && !line.start_with?("#", ">", "-", "* ", "1.") && line.strip != "---" }.to_s
  description = plain_text(description_source)
  body_html = render_body(raw_lines)

  slug = slug_for(source_path)
  {
    title: title,
    title_h1_html: title_h1_html,
    date: date,
    description: description,
    body_html: body_html,
    slug: slug,
    source_path: source_path
  }
end

def write_post_html(post)
  output_path = File.join(BLOG_DIR, post[:slug])
  html = <<~HTML
    <!DOCTYPE html>
    <html lang="en">
      <head>
        <meta charset="UTF-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1.0" />
        <title>#{html_escape(post[:title])}</title>
        <meta
          name="description"
          content="#{html_escape(post[:description])}"
        />
        <meta property="og:type" content="article" />
        <meta property="og:site_name" content="Nick Raushenbush" />
        <meta property="og:title" content="#{html_escape(post[:title])}" />
        <meta
          property="og:description"
          content="#{html_escape(post[:description])}"
        />
        <meta property="og:url" content="#{SITE_ORIGIN}/blog/#{html_escape(post[:slug])}" />
        <meta property="og:image" content="#{OG_IMAGE_URL}" />
        <meta property="og:image:width" content="1200" />
        <meta property="og:image:height" content="630" />
        <meta name="twitter:card" content="summary_large_image" />
        <meta name="twitter:title" content="#{html_escape(post[:title])}" />
        <meta
          name="twitter:description"
          content="#{html_escape(post[:description])}"
        />
        <meta name="twitter:image" content="#{OG_IMAGE_URL}" />
        <meta http-equiv="Content-Security-Policy" content="#{CONTENT_SECURITY_POLICY}" />
        <script src="../js/theme-init.js?v=#{THEME_ASSET_VERSION}"></script>
        <link rel="icon" href="../assets/favicon.svg?v=#{FAVICON_QUERY}" type="image/svg+xml" />
        <link rel="stylesheet" href="../site.min.css?v=#{SITE_CSS_QUERY}" />
      </head>
      <body>
        <div class="page-shell post-page">
          <button
            id="theme-toggle"
            class="theme-toggle"
            type="button"
            aria-label="Switch to dark mode"
            role="switch"
            aria-checked="false"
          ></button>

          <a class="back-link" href="../index.html">Back to home</a>

          <main>
            <header class="post-header">
              <p class="post-meta">#{html_escape(post[:date])}</p>
              <h1>#{post[:title_h1_html]}</h1>
            </header>

            <article class="post-body">
    #{post[:body_html]}
            </article>

            <a class="back-link post-footer-link" href="../index.html">Back to home</a>
          </main>
        </div>
        <script src="../js/theme-toggle.js?v=#{THEME_ASSET_VERSION}"></script>
      </body>
    </html>
  HTML

  File.write(output_path, html)
end

def writing_list_html(posts)
  base = "          "
  posts.map do |post|
    title_esc = html_escape(post[:title])
    date_esc = html_escape(post[:date])
    slug = post[:slug]
    inner = <<~HTML
      <article class="writing-item">
        <h2><a href="blog/#{slug}">#{title_esc}</a></h2>
        <p class="post-meta">#{date_esc}</p>
      </article>
    HTML
    inner.lines.map { |line| "#{base}#{line}" }.join.chomp
  end.join("\n\n")
end

def update_index_writing_list(posts)
  content = File.read(INDEX_PATH)
  unless content.include?(POST_LIST_START) && content.include?(POST_LIST_END)
    warn "Warning: #{INDEX_PATH} missing #{POST_LIST_START} / #{POST_LIST_END}; skipping index update."
    return
  end

  pattern = /#{Regexp.escape(POST_LIST_START)}.*?#{Regexp.escape(POST_LIST_END)}/m
  replacement = "#{POST_LIST_START}\n#{writing_list_html(posts)}\n\n#{POST_LIST_END}"
  File.write(INDEX_PATH, content.sub(pattern, replacement))
end

source_paths = Dir[File.join(SOURCE_DIR, "*.md")].reject do |path|
  File.basename(path).start_with?("_")
end

posts = source_paths.map { |path| parse_source(path) }
posts.sort_by! { |post| sort_time_for_date_string(post[:date]) }
posts.reverse!

posts.each { |post| write_post_html(post) }
update_index_writing_list(posts)

puts "Built #{posts.length} post pages and updated index writing list."
