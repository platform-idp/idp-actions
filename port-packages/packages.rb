#!/usr/bin/env ruby

require 'json'
require 'bundler'

$packages = []

# Extract Python package information from requirements.txt
def extract_python_packages
  return unless File.exist?('requirements.txt')

  $packages += File.readlines('requirements.txt').map do |line|
    name, version = line.strip.split('==')
    {"properties" => {"name" => name, "version" => version, "language" => "Python"}, "blueprint" => "package", "identifier" => "#{name}@#{version}", "title" => "#{name}@#{version}"}
  end
end

# Extract Node.js package information from package.json
def extract_node_packages
  return unless File.exist?('package.json')

  package_json = JSON.parse(File.read('package.json'))
  $packages += (package_json['dependencies'] || {}).merge(package_json['devDependencies'] || {}).map do |key, value|
    pname = key.gsub('@', '')
    {"properties" => {"name" => pname, "version" => value, "language" => "Node"}, "blueprint" => "package", "identifier" => "#{pname.gsub(/[\/.^]/, '-')}@#{value}", "title" => "#{pname}@#{value}"}
  end
end

# Extract Go package information from go.mod
def extract_go_packages
  return unless File.exist?('go.mod')

  in_require_block = false

  # Regex pattern to match and capture host
  host_pattern = /^(https?:\/\/)?([^\/]+)\/(.+)$/

  File.readlines('go.mod').each do |line|
    if line =~ /^require\s+\(/
      in_require_block = true
    elsif line =~ /^\)\s*$/
      in_require_block = false
    elsif in_require_block && line =~ /^\s*([^\s]+)\s+([^\s]+)\s*$/
      name_with_host, version = $1, $2.gsub(/\+incompatible$/, '')

      # Use regex to match and capture host
      match = name_with_host.match(host_pattern)

      if match
        host, name = match.captures[1..2] # Extract the second and third captured groups
      else
        host = nil
        name = name_with_host
      end

      # $packages << {"properties" => {"name" => name, "version" => version, "language" => "Go"}, "blueprint" => "package", "identifier" => "#{name_with_host}@#{version}", "title" => "#{name}@#{version}"}
      # We should consider identifier as package after trimming host.
      $packages << {"properties" => {"name" => name, "version" => version, "language" => "Go"}, "blueprint" => "package", "identifier" => "#{name}@#{version}", "title" => "#{name}@#{version}"}
    end
  end
end

# Extract Ruby package information from Gemfile.lock
def extract_ruby_packages
  return unless File.exist?('Gemfile.lock')
  parser = Bundler::LockfileParser.new(Bundler.read_file('Gemfile.lock'))
  parser.specs.each { |spec|
    name, version = spec.name, spec.version.to_s
    $packages << {"properties" => {"name" => name, "version" => version.to_s, "language" => "Ruby"}, "blueprint" => "package", "identifier" => "#{name}@#{version}", "title" => "#{name}@#{version}"}
  }
end

# Helper method to write packages to the output file
def write_to_file(packages=$packages)
  File.open('packages.txt', 'a') do |file|
    file.puts 'packages=' + JSON.generate(packages)
  end
end

# Main script
extract_python_packages
extract_node_packages
extract_go_packages
extract_ruby_packages
write_to_file

