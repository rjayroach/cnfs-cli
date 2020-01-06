# frozen_string_literal: true
require 'tty-table'

module Primary
  class StatusController < ApplicationController
    def execute
      each_target do |target|
        # before_execute_on_target
        execute_on_target
      end
    end

    def execute_on_target
      header = %w[Application Status Target Status_]
      table = TTY::Table.new(header: header, rows: rows)

      output.puts "\nServices"
      output.puts table.render(:basic, alignments: [:left, :left], padding: [0, 4, 0, 0])

      output.puts "\nResources"
      stuff = [target.application, target].each.map(&:resources).flatten.compact.map { |svc| [svc.type, svc.name, svc.config.to_s] }
      output.puts TTY::Table.new(header: ['type', 'name', 'config'], rows: stuff).render(:basic, padding: [0, 4, 0, 0])

      output.puts "\nDeployment: #{target.deployment.name}\tTarget: #{target.name}\tApplication: #{target.application.name}"
      show_endpoint
    end

    # TODO: Get the endpoint(s) from the application+target
    def show_endpoint
      output.puts "\n*** Services available at #{target.application.endpoints['api'].cnfs_sub(target)} ***"
      output.puts "*** API Docs available at [TO IMPLEMENT] ***\n\n"
    end

    def rows
      # Format results into an array that TTY::Table can handle
      all_services = compile_services
      rows = all_services.values.map(&:size).max
      @result = Array.new(rows) do
        all_services.keys.each_with_object([]) do |key, ary|
          # pad results with nil if there is no value
          ary.append(all_services[key].shift || [nil, nil])
        end.flatten
      end
    end

    def compile_services
      [target.application, target].each_with_object({}) do |layer, hash|
        hash[layer.name] = []
        layer.services.order(:name).each do |service|
          profiles = service.respond_to?(:profiles) ? service.profiles.sort : %w[server]
          profiles.each do |profile|
            service_name = profile.eql?('server') ? service.name : "#{service.name}_#{profile}"
            status = target.runtime.service_names.include?(service_name.to_s) ? 'Running' : 'Stopped'
            hash[layer.name].append([service_name, status])
          end
        end
      end
    end
  end
end
