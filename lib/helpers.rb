require "yaml"

use_helper Nanoc::Helpers::Rendering

def is_page_selected(page)
  (@item.identifier.without_ext == page) ? "selected" : ""
end

class YamlData
  def method_missing(method_name, *arguments, &block)
    YAML.safe_load_file(File.join(File.expand_path("..", __dir__), "data", "#{method_name}.yml"), symbolize_names: true)
  end

  def respond_to_missing?(method_name, include_private = false)
    File.exist?(File.join(File.expand_path("..", __dir__), "data", "#{method_name}.yml")) || super
    true
  end
end

def data
  YamlData.new
end
