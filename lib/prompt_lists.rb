# frozen_string_literal: true

require 'yaml'

module PromptLists
  VERSION = '0.1.0'

  class List
    attr_reader :id, :sublist_names

    def initialize(list_name, sublist_names)
      @id = list_name.to_sym
      @sublist_names = sublist_names
    end

    def method_missing(method_name, *args)
      sublist = @sublist_names.find { |sublist| sublist == method_name }
      if sublist
        sublist_filename = method_name.to_s.gsub(/_/, "-")
        path = File.expand_path("../lists/#{@id}/#{sublist_filename}.yml", __dir__)
        Sublist.new(path)
      else
        super
      end
    end

    def respond_to_missing?(method_name, include_private = false)
      sublist = @sublist_names.find { |sublist| sublist == method_name }
      sublist || super
    end
  end

  class Sublist
    attr_reader :id
    attr_accessor :metadata, :items
    def initialize(file_path)
      @file_path = file_path
      @id = File.basename(file_path, ".yml").gsub(/-/, "_").to_sym
      @content = File.read(@file_path)
      if @content =~ /^(---\s*\n.*?\n?)^(---\s*$\n?)/m
        @items = @content[($1.size + $2.size)..-1].split("\n")
        @metadata = YAML.load($1)
      end
      @metadata = (@metadata || {})
    end
  end

  class << self
    def all
      Dir[File.expand_path("../lists/*", __dir__)].map do |list|
        list_name = File.basename(list)
        List.new(list_name, load_sublists(list_name))
      end
    end

    def find(list_name)
      if list_exists?(list_name)
        List.new(list_name, load_sublists(list_name))
      end
    end

    def method_missing(method_name, *args)
      find(method_name) || super
    end

    private

    def load_sublists(list_name)
      Dir[File.expand_path("../lists/#{list_name}/*.yml", __dir__)].map do |file_path|
        File.basename(file_path, ".yml").gsub(/-/, "_").to_sym
      end
    end

    def list_exists?(list_name)
      Dir.exist?(File.expand_path("../lists/#{list_name}", __dir__))
    end
  end
end
