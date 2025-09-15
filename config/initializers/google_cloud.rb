if ENV['GOOGLE_APPLICATION_CREDENTIALS_JSON']
  require 'tempfile'

  file = Tempfile.new('google-credentials')
  file.write(ENV['GOOGLE_APPLICATION_CREDENTIALS_JSON'])
  file.rewind

  ENV['GOOGLE_APPLICATION_CREDENTIALS'] = file.path

  at_exit { file.unlink }
end
