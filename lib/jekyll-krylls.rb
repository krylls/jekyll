$:.unshift File.dirname(__FILE__)     # For use/testing when no gem is installed

# rubygems
require 'rubygems'

# core
require 'fileutils'
require 'time'
require 'yaml'

# stdlib

# 3rd party
require 'liquid'
require 'redcloth'

# internal requires
require 'jekyll-krylls/core_ext'
require 'jekyll-krylls/pager'
require 'jekyll-krylls/site'
require 'jekyll-krylls/convertible'
require 'jekyll-krylls/layout'
require 'jekyll-krylls/page'
require 'jekyll-krylls/news_item'
require 'jekyll-krylls/show'
require 'jekyll-krylls/venue'
require 'jekyll-krylls/filters'
require 'jekyll-krylls/tags/highlight'
require 'jekyll-krylls/tags/include'
require 'jekyll-krylls/albino'
require 'jekyll-krylls/static_file'

module Jekyll
  # Default options. Overriden by values in _config.yml or command-line opts.
  # (Strings rather symbols used for compatability with YAML)
  DEFAULTS = {
    'auto'         => false,
    'server'       => false,
    'server_port'  => 4000,

    'source'       => '.',
    'destination'  => File.join('.', '_site'),

    'lsi'          => false,
    'pygments'     => false,
    'markdown'     => 'maruku',
    'permalink'    => 'date',

    'maruku'       => {
      'use_tex'    => false,
      'use_divs'   => false,
      'png_engine' => 'blahtex',
      'png_dir'    => 'images/latex',
      'png_url'    => '/images/latex'
    }
  }

  # Generate a Jekyll configuration Hash by merging the default options
  # with anything in _config.yml, and adding the given options on top
  #   +override+ is a Hash of config directives
  #
  # Returns Hash
  def self.configuration(override)
    # _config.yml may override default source location, but until
    # then, we need to know where to look for _config.yml
    source = override['source'] || Jekyll::DEFAULTS['source']

    # Get configuration from <source>/_config.yml
    config_file = File.join(source, '_config.yml')
    begin
      config = YAML.load_file(config_file)
      raise "Invalid configuration - #{config_file}" if !config.is_a?(Hash)
      $stdout.puts "Configuration from #{config_file}"
    rescue => err
      $stderr.puts "WARNING: Could not read configuration. Using defaults (and options)."
      $stderr.puts "\t" + err.to_s
      config = {}
    end

    # Merge DEFAULTS < _config.yml < override
    Jekyll::DEFAULTS.deep_merge(config).deep_merge(override)
  end

  def self.version
    yml = YAML.load(File.read(File.join(File.dirname(__FILE__), *%w[.. VERSION.yml])))
    "#{yml[:major]}.#{yml[:minor]}.#{yml[:patch]}"
  end
end
