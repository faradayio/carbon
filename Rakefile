#!/usr/bin/env rake
require "bundler/gem_tasks"

require 'rake'
require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib'
  test.pattern = 'test/**/*_test.rb'
  test.verbose = true
end

require 'cucumber/rake/task'
Cucumber::Rake::Task.new

require 'yard'
YARD::Rake::YardocTask.new do |y|
  y.options << '--no-private' << '--title' << "Brighter Planet CM1 client for Ruby"
end

task :default => [:test, :cucumber]
