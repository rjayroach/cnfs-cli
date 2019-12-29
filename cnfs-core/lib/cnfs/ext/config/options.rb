# frozen_string_literal: true

# monkeypatch Config gem's Options class to add instance method #to_array
# which returns an array representation of the Config hash
module Config
  class Options
    def to_array(key = '', value = self, ary = [])
      if value.is_a?(Config::Options)
        value.each_pair do |skey, value|
          to_array("#{key}#{key.empty? ? '' : Config.env_separator}#{skey}", value, ary)
        end
      else
        if value.is_a? Array
          ary.append("#{key.upcase}=#{value.join("\n")}")
        else
          ary.append("#{key.upcase}=#{value}") unless value.nil?
        end
      end
      ary
    end
  end
end
