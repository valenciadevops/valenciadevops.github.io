require "yaml"

use_helper Nanoc::Helpers::Rendering

def is_page_selected(page)
  (@item.identifier.without_ext == page) ? "selected" : ""
end

class YamlData
  include Singleton

  def initialize
    @datas = {}
  end

  def filename(name)
    File.join(File.expand_path("..", __dir__), "data", "#{name}.yml")
  end

  def method_missing(method_name, *arguments, &block)
    @datas.fetch(method_name) do
      filename = filename(method_name)
      @datas[method_name] = YAML.safe_load_file(filename, symbolize_names: true)
    end
  end

  def respond_to_missing?(method_name, include_private = false)
    filename = filename(method_name)
    File.exist?(filename) || super
    true
  end
end

def data
  YamlData.instance
end
