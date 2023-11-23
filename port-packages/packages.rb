#!/usr/bin/env ruby

require 'json'

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
    {"properties" => {"name" => key, "version" => value, "language" => "Node"}, "blueprint" => "package", "identifier" => "#{key.gsub(/[\/.^]/, '-')}@#{value}", "title" => "#{key}@#{value}"}
  end
end

# Extract Go package information from go.mod
def extract_go_packages
  return unless File.exist?('go.mod')

  in_require_block = false

  File.readlines('go.mod').each do |line|
    if line =~ /^require\s+\(/
      in_require_block = true
    elsif line =~ /^\)\s*$/
      in_require_block = false
    elsif in_require_block && line =~ /^\s*([^\s]+)\s+([^\s]+)\s*$/
      name, version = $1, $2
      $packages << {"properties" => {"name" => name, "version" => version, "language" => "Go"}, "blueprint" => "package", "identifier" => "#{name}@#{version}", "title" => "#{name}@#{version}"}
    end
  end
end

# Extract Ruby package information from Gemfile.lock
def extract_ruby_packages
  return unless File.exist?('Gemfile.lock')

  in_specification_block = false

  File.readlines('Gemfile.lock').each do |line|
    line.strip!

    if line.start_with?('GEM')
      in_specification_block = true
    elsif in_specification_block && line =~ /^(\S+)\s+\(([^,]+),.*\)$/
      name, version = $1, $2
      $packages << {"properties" => {"name" => name, "version" => version, "language" => "Ruby"}, "blueprint" => "package", "identifier" => "#{name}@#{version}", "title" => "#{name}@#{version}"}
    elsif line.empty? && in_specification_block
      in_specification_block = false
    end
  end
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
