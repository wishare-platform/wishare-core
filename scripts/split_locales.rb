#!/usr/bin/env ruby
require 'yaml'
require 'fileutils'

def split_locale_file(locale)
  input_file = "config/locales/#{locale}.yml"
  output_dir = "config/locales/#{locale}"

  unless File.exist?(input_file)
    puts "File #{input_file} not found"
    return
  end

  data = YAML.load_file(input_file)
  locale_key = data.keys.first

  # Define how to split the files
  splits = {
    'app.yml' => ['app', 'landing', 'navigation', 'theme', 'cookie_consent'],
    'auth.yml' => ['auth'],
    'dashboard.yml' => ['dashboard'],
    'profile.yml' => ['profile'],
    'wishlists.yml' => ['wishlists', 'items', 'wishlist_items'],
    'social.yml' => ['connections', 'invitations', 'users'],
    'notifications.yml' => ['notifications', 'notification_preferences', 'emails'],
    'admin.yml' => ['admin'],
    'common.yml' => ['common', 'errors', 'address_lookup'],
    'activerecord.yml' => ['activerecord'],
    'formats.yml' => ['date', 'time', 'number'],
    'event_types.yml' => ['event_types']
  }

  # Create output directory
  FileUtils.mkdir_p(output_dir)

  # Split the data
  splits.each do |filename, keys|
    file_data = { locale_key => {} }

    keys.each do |key|
      if data[locale_key] && data[locale_key][key]
        file_data[locale_key][key] = data[locale_key][key]
      end
    end

    # Only write file if it has content
    if file_data[locale_key].any?
      output_path = File.join(output_dir, filename)
      File.write(output_path, file_data.to_yaml)
      puts "Created #{output_path} with keys: #{keys.join(', ')}"
    end
  end

  # Check for any missed keys
  all_keys = splits.values.flatten
  missed_keys = data[locale_key].keys - all_keys

  if missed_keys.any?
    puts "WARNING: Missed keys: #{missed_keys.join(', ')}"
  end

  # Create a backup of original file
  backup_file = "#{input_file}.backup"
  FileUtils.cp(input_file, backup_file)
  puts "Created backup: #{backup_file}"

  # Create index file that loads all splits
  index_content = <<~YAML
    # This file loads all split locale files for #{locale}
    # Original file backed up to #{locale}.yml.backup

    #{locale_key}:
      # All translations are now in subdirectories
      # Rails will automatically load all .yml files in config/locales/**
  YAML

  File.write(input_file, index_content)
  puts "Updated #{input_file} as index file"
end

# Split both locale files
['en', 'pt-BR'].each do |locale|
  puts "\nSplitting #{locale} locale file..."
  split_locale_file(locale)
end

puts "\n✅ Locale files split successfully!"
puts "Rails will automatically load all .yml files in config/locales/**"
puts "Original files backed up with .backup extension"