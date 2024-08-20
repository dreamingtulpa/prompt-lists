# frozen_string_literal: true

require 'yaml'

module PromptLists
  VERSION = '0.0.1'

  class List
    def initialize(file_paths)
      @sublists = file_paths.map do |file_path|
        id = File.basename(file_path, ".yml").gsub("-", "_").to_sym
        Hash[id, file_path]
      end
    end

    def method_missing(method_name, *args)
      sublist = @sublists.find { |sublist| sublist.key?(method_name) }
      if sublist
        Sublist.new(sublist.values[0])
      else
        super
      end
    end

    def respond_to_missing?(method_name, include_private = false)
      sublist = @sublists.find { |sublist| sublist.key?(method_name) }
      sublist || super
    end
  end

  class Sublist
    def initialize(file_path)
      @file_path = file_path
      @content = File.read(@file_path)
      if @content =~ /^(---\s*\n.*?\n?)^(---\s*$\n?)/m
        @items = @content[($1.size + $2.size)..-1].split("\n")
        @metadata = YAML.load($1)
      end
      @metadata = (@metadata || {})
    end
    attr_accessor :metadata, :items
  end

  class << self
    def method_missing(method_name, *args)
      list_name = method_name.to_s
      if list_exists?(list_name)
        result = load_list(list_name)
        List.new(result)
      else
        super
      end
    end

    def respond_to_missing?(method_name, include_private = false)
      list_exists?(method_name.to_s) || super
    end

    private

    def load_list(list_name)
      Dir["lists/#{list_name}/*.yml"]
    end

    def list_exists?(list_name)
      Dir.exist?("lists/#{list_name}")
    end
  end
end
