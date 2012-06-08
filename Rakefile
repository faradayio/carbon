#!/usr/bin/env rake

require 'bundler/setup'

require 'bundler/gem_tasks'

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new
task :test => :spec

require 'cucumber/rake/task'
Cucumber::Rake::Task.new

require 'yard'
YARD::Rake::YardocTask.new do |y|
  y.options << '--no-private' << '--title' << "Brighter Planet CM1 client for Ruby"
end

task :default => [:spec, :cucumber]

namespace :avro do
  task :setup do
    require 'rubygems'
    require 'bundler/setup'
    require File.expand_path("../developer/avro_helper", __FILE__)
    require File.expand_path("../developer/cm1_avro", __FILE__)
    @cm1 = Cm1Avro::Impact.new
  end
  task :api_paths => 'avro:setup' do
    ary = []
    AvroHelper.api_paths(@cm1.avro_response_schema) { |path| ary << path }
    $stdout.write ary.sort.join("\n")
  end
  task :json => 'avro:setup' do
    $stdout.write MultiJson.dump(@cm1.avro_response_schema)
  end
  task :example => 'avro:setup' do
    require 'tempfile'
    file = Tempfile.new('com.brighterplanet.Cm1.example.avr')
    parsed_schema = Avro::Schema.parse(MultiJson.dump(@cm1.avro_response_schema))
    writer = Avro::IO::DatumWriter.new(parsed_schema)
    dw = Avro::DataFile::Writer.new(file, writer, parsed_schema)
    dw << AvroHelper.recursively_stringify_keys(@cm1.example)
    dw.close
    file.close
    $stdout.write File.read(file.path)
  end
end
