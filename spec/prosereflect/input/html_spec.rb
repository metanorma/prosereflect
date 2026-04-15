# frozen_string_literal: true

require "spec_helper"

RSpec.describe Prosereflect::Input::Html do
  describe ".parse" do
    it "parses simple HTML into a document" do
      html = "<p>This is a test paragraph.</p>"
      document = described_class.parse(html)

      expected = {
        "type" => "doc",
        "content" => [{
          "type" => "paragraph",
          "content" => [{
            "type" => "text",
            "text" => "This is a test paragraph.",
          }],
        }],
      }

      expect(document.to_h).to eq(expected)
    end

    it "renders basic styled text correctly" do
      html = "<p>This is <strong>bold</strong> and <em>italic</em> text.</p>"
      document = described_class.parse(html)

      expected = {
        "type" => "doc",
        "content" => [{
          "type" => "paragraph",
          "content" => [{
            "type" => "text",
            "text" => "This is ",
          }, {
            "type" => "text",
            "text" => "bold",
            "marks" => [{
              "type" => "bold",
            }],
          }, {
            "type" => "text",
            "text" => " and ",
          }, {
            "type" => "text",
            "text" => "italic",
            "marks" => [{
              "type" => "italic",
            }],
          }, {
            "type" => "text",
            "text" => " text.",
          }],
        }],
      }

      expect(document.to_h).to eq(expected)
    end

    it "parses strike text correctly" do
      html = "<p>This is <strike>struck through</strike> text and <s>this too</s> and <del>deleted</del>.</p>"
      document = described_class.parse(html)

      expected = {
        "type" => "doc",
        "content" => [{
          "type" => "paragraph",
          "content" => [{
            "type" => "text",
            "text" => "This is ",
          }, {
            "type" => "text",
            "text" => "struck through",
            "marks" => [{
              "type" => "strike",
            }],
          }, {
            "type" => "text",
            "text" => " text and ",
          }, {
            "type" => "text",
            "text" => "this too",
            "marks" => [{
              "type" => "strike",
            }],
          }, {
            "type" => "text",
            "text" => " and ",
          }, {
            "type" => "text",
            "text" => "deleted",
            "marks" => [{
              "type" => "strike",
            }],
          }, {
            "type" => "text",
            "text" => ".",
          }],
        }],
      }

      expect(document.to_h).to eq(expected)
    end

    it "parses subscript text correctly" do
      html = "<p>H<sub>2</sub>O and E = mc<sub>2</sub></p>"
      document = described_class.parse(html)

      expected = {
        "type" => "doc",
        "content" => [{
          "type" => "paragraph",
          "content" => [{
            "type" => "text",
            "text" => "H",
          }, {
            "type" => "text",
            "text" => "2",
            "marks" => [{
              "type" => "subscript",
            }],
          }, {
            "type" => "text",
            "text" => "O and E = mc",
          }, {
            "type" => "text",
            "text" => "2",
            "marks" => [{
              "type" => "subscript",
            }],
          }],
        }],
      }

      expect(document.to_h).to eq(expected)
    end

    it "parses superscript text correctly" do
      html = "<p>x<sup>2</sup> + y<sup>2</sup> = z<sup>2</sup></p>"
      document = described_class.parse(html)

      expected = {
        "type" => "doc",
        "content" => [{
          "type" => "paragraph",
          "content" => [{
            "type" => "text",
            "text" => "x",
          }, {
            "type" => "text",
            "text" => "2",
            "marks" => [{
              "type" => "superscript",
            }],
          }, {
            "type" => "text",
            "text" => " + y",
          }, {
            "type" => "text",
            "text" => "2",
            "marks" => [{
              "type" => "superscript",
            }],
          }, {
            "type" => "text",
            "text" => " = z",
          }, {
            "type" => "text",
            "text" => "2",
            "marks" => [{
              "type" => "superscript",
            }],
          }],
        }],
      }

      expect(document.to_h).to eq(expected)
    end

    it "parses underlined text correctly" do
      html = "<p>This is <u>underlined</u> text.</p>"
      document = described_class.parse(html)

      expected = {
        "type" => "doc",
        "content" => [{
          "type" => "paragraph",
          "content" => [{
            "type" => "text",
            "text" => "This is ",
          }, {
            "type" => "text",
            "text" => "underlined",
            "marks" => [{
              "type" => "underline",
            }],
          }, {
            "type" => "text",
            "text" => " text.",
          }],
        }],
      }

      expect(document.to_h).to eq(expected)
    end

    it "handles mixed text styles correctly" do
      html = "<p><strong><u>Bold and underlined</u></strong> and <em><strike>italic struck</strike></em></p>"
      document = described_class.parse(html)

      expected = {
        "type" => "doc",
        "content" => [{
          "type" => "paragraph",
          "content" => [{
            "type" => "text",
            "text" => "Bold and underlined",
            "marks" => [{
              "type" => "underline",
            }, {
              "type" => "bold",
            }],
          }, {
            "type" => "text",
            "text" => " and ",
          }, {
            "type" => "text",
            "text" => "italic struck",
            "marks" => [{
              "type" => "strike",
            }, {
              "type" => "italic",
            }],
          }],
        }],
      }

      expect(document.to_h).to eq(expected)
    end

    it "handles complex mixed text styles correctly" do
      html = "<p>x<sup>2</sup> + <u>y<sub>1</sub></u> = <strike>z<sup>n</sup></strike></p>"
      document = described_class.parse(html)

      expected = {
        "type" => "doc",
        "content" => [{
          "type" => "paragraph",
          "content" => [{
            "type" => "text",
            "text" => "x",
          }, {
            "type" => "text",
            "text" => "2",
            "marks" => [{
              "type" => "superscript",
            }],
          }, {
            "type" => "text",
            "text" => " + ",
          }, {
            "type" => "text",
            "text" => "y",
            "marks" => [{
              "type" => "underline",
            }],
          }, {
            "type" => "text",
            "text" => "1",
            "marks" => [{
              "type" => "subscript",
            }, {
              "type" => "underline",
            }],
          }, {
            "type" => "text",
            "text" => " = ",
          }, {
            "type" => "text",
            "text" => "z",
            "marks" => [{
              "type" => "strike",
            }],
          }, {
            "type" => "text",
            "text" => "n",
            "marks" => [{
              "type" => "superscript",
            }, {
              "type" => "strike",
            }],
          }],
        }],
      }

      expect(document.to_h).to eq(expected)
    end

    it "parses tables correctly" do
      html = <<~HTML
        <table>
          <tr>
            <td>Row 1, Cell 1</td>
            <td>Row 1, Cell 2</td>
          </tr>
          <tr>
            <td>Row 2, Cell 1</td>
            <td>Row 2, Cell 2</td>
          </tr>
        </table>
      HTML

      document = described_class.parse(html)

      expected = {
        "type" => "doc",
        "content" => [{
          "type" => "table",
          "content" => [{
            "type" => "table_row",
            "content" => [{
              "type" => "table_cell",
              "content" => [{
                "type" => "paragraph",
                "content" => [{
                  "type" => "text",
                  "text" => "Row 1, Cell 1",
                }],
              }],
            }, {
              "type" => "table_cell",
              "content" => [{
                "type" => "paragraph",
                "content" => [{
                  "type" => "text",
                  "text" => "Row 1, Cell 2",
                }],
              }],
            }],
          }, {
            "type" => "table_row",
            "content" => [{
              "type" => "table_cell",
              "content" => [{
                "type" => "paragraph",
                "content" => [{
                  "type" => "text",
                  "text" => "Row 2, Cell 1",
                }],
              }],
            }, {
              "type" => "table_cell",
              "content" => [{
                "type" => "paragraph",
                "content" => [{
                  "type" => "text",
                  "text" => "Row 2, Cell 2",
                }],
              }],
            }],
          }],
        }],
      }

      expect(document.to_h).to eq(expected)
    end

    it "parses links correctly" do
      html = '<p>This is a <a href="https://example.com">link</a></p>'
      document = described_class.parse(html)

      expected = {
        "type" => "doc",
        "content" => [{
          "type" => "paragraph",
          "content" => [{
            "type" => "text",
            "text" => "This is a ",
          }, {
            "type" => "text",
            "text" => "link",
            "marks" => [{
              "type" => "link",
              "attrs" => {
                "href" => "https://example.com",
              },
            }],
          }],
        }],
      }

      expect(document.to_h).to eq(expected)
    end

    it "handles line breaks correctly" do
      html = "<p>Line 1<br>Line 2</p>"
      document = described_class.parse(html)

      expected = {
        "type" => "doc",
        "content" => [{
          "type" => "paragraph",
          "content" => [{
            "type" => "text",
            "text" => "Line 1",
          }, {
            "type" => "hard_break",
          }, {
            "type" => "text",
            "text" => "Line 2",
          }],
        }],
      }

      expect(document.to_h).to eq(expected)
    end

    it "parses ordered lists with start attribute correctly" do
      html = <<~HTML
        <ol start="3">
          <li>Third item</li>
          <li>Fourth item</li>
        </ol>
      HTML

      document = described_class.parse(html)

      expected = {
        "type" => "doc",
        "content" => [{
          "type" => "ordered_list",
          "attrs" => {
            "start" => 3,
          },
          "content" => [{
            "type" => "list_item",
            "content" => [{
              "type" => "paragraph",
              "content" => [{
                "type" => "text",
                "text" => "Third item",
              }],
            }],
          }, {
            "type" => "list_item",
            "content" => [{
              "type" => "paragraph",
              "content" => [{
                "type" => "text",
                "text" => "Fourth item",
              }],
            }],
          }],
        }],
      }

      expect(document.to_h).to eq(expected)
    end

    it "parses bullet lists with styles correctly" do
      html = <<~HTML
        <ul style="list-style-type: square">
          <li>First bullet</li>
          <li>Second bullet</li>
        </ul>
      HTML

      document = described_class.parse(html)

      expected = {
        "type" => "doc",
        "content" => [{
          "type" => "bullet_list",
          "attrs" => {
            "bullet_style" => "square",
          },
          "content" => [{
            "type" => "list_item",
            "content" => [{
              "type" => "paragraph",
              "content" => [{
                "type" => "text",
                "text" => "First bullet",
              }],
            }],
          }, {
            "type" => "list_item",
            "content" => [{
              "type" => "paragraph",
              "content" => [{
                "type" => "text",
                "text" => "Second bullet",
              }],
            }],
          }],
        }],
      }

      expect(document.to_h).to eq(expected)
    end

    it "renders headings with mixed content correctly" do
      html = <<~HTML
        <h1>Title with <strong>bold</strong> and <a href="https://example.com">link</a></h1>
      HTML

      expected = {
        "type" => "doc",
        "content" => [{
          "type" => "heading",
          "attrs" => {
            "level" => 1,
          },
          "content" => [{
            "type" => "text",
            "text" => "Title with ",
          }, {
            "type" => "text",
            "text" => "bold",
            "marks" => [{
              "type" => "bold",
            }],
          }, {
            "type" => "text",
            "text" => " and ",
          }, {
            "type" => "text",
            "text" => "link",
            "marks" => [{
              "type" => "link",
              "attrs" => {
                "href" => "https://example.com",
              },
            }],
          }],
        }],
      }

      document = described_class.parse(html)
      expect(document.to_h).to eq(expected)
    end

    it "renders lists with nested content correctly" do
      html = <<~HTML
        <ul>
          <li>First item with <em>emphasis</em></li>
          <li>Second item with <code>code</code></li>
        </ul>
      HTML

      expected = {
        "type" => "doc",
        "content" => [{
          "type" => "bullet_list",
          "attrs" => {
            "bullet_style" => nil,
          },
          "content" => [{
            "type" => "list_item",
            "content" => [{
              "type" => "paragraph",
              "content" => [{
                "type" => "text",
                "text" => "First item with ",
              }, {
                "type" => "text",
                "text" => "emphasis",
                "marks" => [{
                  "type" => "italic",
                }],
              }],
            }],
          }, {
            "type" => "list_item",
            "content" => [{
              "type" => "paragraph",
              "content" => [{
                "type" => "text",
                "text" => "Second item with ",
              }, {
                "type" => "text",
                "text" => "code",
                "marks" => [{
                  "type" => "code",
                }],
              }],
            }],
          }],
        }],
      }

      document = described_class.parse(html)
      expect(document.to_h).to eq(expected)
    end

    it "renders blockquotes with citations correctly" do
      html = <<~HTML
        <blockquote cite="https://example.com">
          <p>A quote with <strong>bold</strong> text</p>
        </blockquote>
      HTML

      expected = {
        "type" => "doc",
        "content" => [{
          "type" => "blockquote",
          "attrs" => {
            "citation" => "https://example.com",
          },
          "content" => [{
            "type" => "paragraph",
            "content" => [{
              "type" => "text",
              "text" => "A quote with ",
            }, {
              "type" => "text",
              "text" => "bold",
              "marks" => [{
                "type" => "bold",
              }],
            }, {
              "type" => "text",
              "text" => " text",
            }],
          }],
        }],
      }

      document = described_class.parse(html)
      expect(document.to_h).to eq(expected)
    end

    it "renders code blocks with language correctly" do
      html = <<~HTML
                <pre><code class="language-ruby">def example
          puts "Hello"
        end</code></pre>
      HTML

      expected = {
        "type" => "doc",
        "content" => [{
          "type" => "code_block_wrapper",
          "attrs" => {
            "line_numbers" => false,
          },
          "content" => [{
            "type" => "code_block",
            "attrs" => {
              "language" => "ruby",
            },
            "content" => ["def example\n  puts \"Hello\"\nend"],
          }],
        }],
      }

      document = described_class.parse(html)
      expect(document.to_h).to eq(expected)
    end

    it "renders images with attributes correctly" do
      html = '<img src="test.jpg" alt="Test image" title="Test title" width="800" height="600">'

      expected = {
        "type" => "doc",
        "content" => [{
          "type" => "image",
          "attrs" => {
            "src" => "test.jpg",
            "alt" => "Test image",
            "title" => "Test title",
            "width" => 800,
            "height" => 600,
          },
        }],
      }

      document = described_class.parse(html)
      expect(document.to_h).to eq(expected)
    end

    it "renders horizontal rules with styles correctly" do
      html = '<hr style="border-style: dashed; width: 80%; border-width: 2px">'

      expected = {
        "type" => "doc",
        "content" => [{
          "type" => "horizontal_rule",
          "attrs" => {
            "style" => "dashed",
            "width" => "80%",
            "thickness" => 2,
          },
        }],
      }

      document = described_class.parse(html)
      expect(document.to_h).to eq(expected)
    end

    it "parses user mentions correctly" do
      html = '<user-mention data-id="123"></user-mention>'

      expected = {
        "type" => "doc",
        "content" => [{
          "type" => "user",
          "attrs" => {
            "id" => "123",
          },
          "content" => [],
        }],
      }

      document = described_class.parse(html)
      expect(document.to_h).to eq(expected)
    end

    it "parses user mentions in paragraphs" do
      html = '<p>Hello <user-mention data-id="123"></user-mention>!</p>'

      expected = {
        "type" => "doc",
        "content" => [{
          "type" => "paragraph",
          "content" => [
            {
              "type" => "text",
              "text" => "Hello ",
            },
            {
              "type" => "user",
              "attrs" => {
                "id" => "123",
              },
              "content" => [],
            },
            {
              "type" => "text",
              "text" => "!",
            },
          ],
        }],
      }

      document = described_class.parse(html)
      expect(document.to_h).to eq(expected)
    end

    it "ignores user mentions without data-id" do
      html = "<user-mention></user-mention>"

      expected = {
        "type" => "doc",
      }

      document = described_class.parse(html)
      expect(document.to_h).to eq(expected)
    end

    it "parses multiple user mentions" do
      html = '<div>Mentioned: <user-mention data-id="123"></user-mention> and <user-mention data-id="456"></user-mention></div>'

      expected = {
        "type" => "doc",
        "content" => [
          {
            "type" => "text",
            "text" => "Mentioned: ",
          },
          {
            "type" => "user",
            "attrs" => {
              "id" => "123",
            },
            "content" => [],
          },
          {
            "type" => "text",
            "text" => " and ",
          },
          {
            "type" => "user",
            "attrs" => {
              "id" => "456",
            },
            "content" => [],
          },
        ],
      }

      document = described_class.parse(html)
      expect(document.to_h).to eq(expected)
    end
  end

  describe ".parse_with_schema" do
    it "parses HTML and returns a document when validation is bypassed" do
      html = "<p>Hello world</p>"
      allow(described_class).to receive(:validate_against_schema)
      document = described_class.send(:parse_with_schema, html, nil)
      expect(document).to be_a(Prosereflect::Document)
      expect(document.to_h["content"].first["type"]).to eq("paragraph")
    end

    it "preserves document content when validation is bypassed" do
      html = "<p>Schema test</p>"
      allow(described_class).to receive(:validate_against_schema)
      document = described_class.send(:parse_with_schema, html, nil)
      para = document.to_h["content"].first
      text_node = para["content"].first
      expect(text_node["text"]).to eq("Schema test")
    end

    it "parses complex HTML with validation bypassed" do
      html = "<h1>Title</h1><p>Paragraph with <strong>bold</strong> text</p>"
      allow(described_class).to receive(:validate_against_schema)
      document = described_class.send(:parse_with_schema, html, nil)
      content = document.to_h["content"]
      expect(content.length).to eq(2)
      expect(content[0]["type"]).to eq("heading")
      expect(content[1]["type"]).to eq("paragraph")
    end

    it "rescues ValidationError and returns the document" do
      html = "<p>Validation error test</p>"
      allow(described_class).to receive(:validate_against_schema).and_raise(
        Prosereflect::Input::Html::ValidationError, "Missing required content"
      )
      document = described_class.send(:parse_with_schema, html, nil)
      expect(document).to be_a(Prosereflect::Document)
      expect(document.to_h["content"].first["type"]).to eq("paragraph")
    end
  end

  describe ".parse_with_rules" do
    it "parses HTML with keep_empty option" do
      html = "<p>Keep empty test</p>"
      document = described_class.send(:parse_with_rules, html, rules: { keep_empty: true })
      expect(document).to be_a(Prosereflect::Document)
      expect(document.to_h["content"].first["type"]).to eq("paragraph")
    end

    it "parses HTML with empty rules" do
      html = "<p>Empty rules test</p>"
      document = described_class.send(:parse_with_rules, html, rules: {})
      expect(document).to be_a(Prosereflect::Document)
    end

    it "preserves content with keep_empty false" do
      html = "<p>Keep empty false</p>"
      document = described_class.send(:parse_with_rules, html, rules: { keep_empty: false })
      para = document.to_h["content"].first
      text_node = para["content"].first
      expect(text_node["text"]).to eq("Keep empty false")
    end

    it "accepts top_node option" do
      html = "<p>Top node test</p>"
      document = described_class.send(:parse_with_rules, html, rules: { top_node: "doc" })
      expect(document.to_h["type"]).to eq("doc")
    end
  end

  describe ".parse_node" do
    it "parses a single HTML paragraph node" do
      doc = Nokogiri::HTML("<p>Single node</p>")
      html_node = doc.at_css("p")
      result = described_class.send(:parse_node, html_node)
      expect(result).to be_a(Prosereflect::Paragraph)
    end

    it "parses a text node" do
      doc = Nokogiri::HTML("<p>text content</p>")
      html_node = doc.at_css("p").children.first
      result = described_class.send(:parse_node, html_node)
      expect(result).to be_a(Prosereflect::Text)
      expect(result.text).to eq("text content")
    end

    it "returns nil for empty text nodes with clear_null" do
      doc = Nokogiri::HTML("<p> </p>")
      html_node = doc.at_css("p").children.first
      result = described_class.send(:parse_node, html_node, clear_null: true)
      expect(result).to be_nil
    end

    it "returns nil for empty text nodes by default" do
      doc = Nokogiri::HTML("<p>   </p>")
      html_node = doc.at_css("p").children.first
      result = described_class.send(:parse_node, html_node)
      expect(result).to be_nil
    end

    it "accepts node option for parent context" do
      doc = Nokogiri::HTML("<p>parent context</p>")
      html_node = doc.at_css("p")
      parent_node = Prosereflect::Document.new
      result = described_class.send(:parse_node, html_node, node: parent_node)
      expect(result).to be_a(Prosereflect::Paragraph)
    end

    it "accepts saved_styles option" do
      doc = Nokogiri::HTML("<p>styled</p>")
      html_node = doc.at_css("p")
      result = described_class.send(:parse_node, html_node, saved_styles: [])
      expect(result).to be_a(Prosereflect::Paragraph)
    end
  end

  describe ".preserve_whitespace?" do
    it "returns true for pre elements" do
      doc = Nokogiri::HTML("<pre>code</pre>")
      pre_node = doc.at_css("pre")
      expect(described_class.send(:preserve_whitespace?, pre_node)).to be true
    end

    it "returns true for textarea elements" do
      doc = Nokogiri::HTML("<textarea>text</textarea>")
      textarea_node = doc.at_css("textarea")
      expect(described_class.send(:preserve_whitespace?, textarea_node)).to be true
    end

    it "returns true for elements with white-space: pre style" do
      doc = Nokogiri::HTML('<div style="white-space: pre">text</div>')
      div_node = doc.at_css("div")
      expect(described_class.send(:preserve_whitespace?, div_node)).to be true
    end

    it "returns false for paragraph elements" do
      doc = Nokogiri::HTML("<p>text</p>")
      p_node = doc.at_css("p")
      expect(described_class.send(:preserve_whitespace?, p_node)).to be false
    end

    it "returns false for elements without white-space style" do
      doc = Nokogiri::HTML('<div style="color: red">text</div>')
      div_node = doc.at_css("div")
      expect(described_class.send(:preserve_whitespace?, div_node)).to be false
    end

    it "returns false for elements without style attribute" do
      doc = Nokogiri::HTML("<div>text</div>")
      div_node = doc.at_css("div")
      expect(described_class.send(:preserve_whitespace?, div_node)).to be false
    end

    it "returns false for elements with white-space but not pre" do
      doc = Nokogiri::HTML('<div style="white-space: nowrap">text</div>')
      div_node = doc.at_css("div")
      expect(described_class.send(:preserve_whitespace?, div_node)).to be false
    end
  end

  describe ".normalize_whitespace" do
    it "replaces multiple spaces with a single space" do
      expect(described_class.send(:normalize_whitespace, "hello   world")).to eq("hello world")
    end

    it "replaces tabs with spaces" do
      expect(described_class.send(:normalize_whitespace, "hello\tworld")).to eq("hello world")
    end

    it "replaces newlines with spaces" do
      expect(described_class.send(:normalize_whitespace, "hello\nworld")).to eq("hello world")
    end

    it "replaces carriage returns with spaces" do
      expect(described_class.send(:normalize_whitespace, "hello\rworld")).to eq("hello world")
    end

    it "strips leading and trailing whitespace" do
      expect(described_class.send(:normalize_whitespace, "  hello  ")).to eq("hello")
    end

    it "handles mixed whitespace" do
      expect(described_class.send(:normalize_whitespace, "  hello \t\n world  ")).to eq("hello world")
    end

    it "returns empty string for whitespace-only input" do
      expect(described_class.send(:normalize_whitespace, "   ")).to eq("")
    end

    it "handles an empty string" do
      expect(described_class.send(:normalize_whitespace, "")).to eq("")
    end

    it "does not modify a clean string" do
      expect(described_class.send(:normalize_whitespace, "hello world")).to eq("hello world")
    end
  end
end
