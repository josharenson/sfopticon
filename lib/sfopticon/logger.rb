require 'logger'

# Singleton logging class subclassed from Ruby's
# built-in Logger

class SfOpticon::Logger
  c = SfOpticon::Settings.logging

  logdev = case c.logdev
  when "STDERR", "", nil
    STDERR
  when "STDOUT"
    STDOUT
  else
    c.logdev
  end

  shift_age = case c.shift_age
  when "", nil
    nil
  else
    c.shift_age
  end

  shift_size = case c.shift_size
  when "", nil
    nil
  else
    c.shift_size
  end

  datetime_format = case c.datetime_format
  when "", nil
    nil
  else
    c.datetime_format
  end

  level = case c.level
  when "", nil
    Logger::DEBUG
  else
    Logger.const_get(c.level)
  end


  @@logger = Logger.new(logdev, shift_age, shift_size)
  @@logger.level = level
  @@logger.datetime_format = datetime_format if datetime_format

  def self.method_missing(name, *args, &block)
    @@logger.send(name, *args, &block)
  end
end
