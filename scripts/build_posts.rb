#!/usr/bin/env ruby
# frozen_string_literal: true

require "cgi"
require "fileutils"

ROOT = File.expand_path("..", __dir__)
SOURCE_DIR = File.join(ROOT, "sources")
BLOG_DIR = File.join(ROOT, "blog")

def html_escape(text)
  CGI.escapeHTML(text)
end

def inline(text)
  escaped = html_escape(text)
  escaped.gsub!(%r{\[([^\]]+)\]\(([^)]+)\)}) do
    label = Regexp.last_match(1)
    href = Regexp.last_match(2)
    attrs = if href.match?(%r{\Ahttps?://})
      %( href="#{CGI.escapeHTML(href)}" target="_blank" rel="noopener noreferrer")
    else
      %( href="#{CGI.escapeHTML(href)}")
    end
    %(<a#{attrs}>#{inline(label)}</a>)
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

posts = Dir[File.join(SOURCE_DIR, "*.md")].sort.map do |source_path|
  raw_lines = File.readlines(source_path, chomp: true)
  title_line = raw_lines.shift
  raise "Missing title in #{source_path}" unless title_line&.start_with?("# ")

  title = title_line.sub(/^#\s+/, "").strip
  raw_lines.shift while raw_lines.first&.strip == ""
  byline = raw_lines.shift.to_s.strip
  date = parse_date(byline)
  raw_lines.shift while raw_lines.first&.strip == ""

  description_source = raw_lines.find { |line| !line.strip.empty? && !line.start_with?("#", ">", "-", "* ", "1.") && line.strip != "---" }.to_s
  description = plain_text(description_source)
  body_html = render_body(raw_lines)

  slug = slug_for(source_path)
  output_path = File.join(BLOG_DIR, slug)
  html = <<~HTML
    <!DOCTYPE html>
    <html lang="en">
      <head>
        <meta charset="UTF-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1.0" />
        <title>#{html_escape(title)}</title>
        <meta
          name="description"
          content="#{html_escape(description)}"
        />
        <link rel="stylesheet" href="../site.css?v=20260319-225900" />
      </head>
      <body>
        <div class="page-shell post-page">
          <a class="back-link" href="../index.html">Back to home</a>

          <main>
            <header class="post-header">
              <p class="post-meta">#{html_escape(date)}</p>
              <h1>#{html_escape(title)}</h1>
            </header>

            <article class="post-body">
    #{body_html}
            </article>

            <a class="back-link post-footer-link" href="../index.html">Back to home</a>
          </main>
        </div>
      </body>
    </html>
  HTML

  File.write(output_path, html)
  { title: title, date: date, slug: slug, source_path: source_path }
end

puts "Built #{posts.length} post pages."
