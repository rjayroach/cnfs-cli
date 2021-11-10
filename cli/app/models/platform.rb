# frozen_string_literal: true

class Platform
  include ActiveModel::Model
  include ActiveModel::Validations

  validate :supported_platform?

  # OS methods
  def gid
    ext_info = OpenStruct.new
    if platform.linux? && Etc.getlogin
      shell_info = Etc.getpwnam(Etc.getlogin)
      ext_info.puid = shell_info.uid
      ext_info.pgid = shell_info.gid
    end
    ext_info
  end

  def capabilities
    @capabilities ||= set_capabilities
  end

  # rubocop:disable Metrics/MethodLength
  def set_capabilities
    cmd = TTY::Command.new(printer: :null)
    installed_tools = []
    missing_tools = []
    tools.each do |tool|
      if cmd.run!("which #{tool}").success?
        installed_tools.append(tool)
      else
        missing_tools.append(tool)
      end
    end
    Cnfs.logger.warn "Missing dependency tools: #{missing_tools.join(', ')}" if missing_tools.any?
    installed_tools
  end
  # rubocop:enable Metrics/MethodLength

  # def tools
  #   Dependency.pluck(:name)
  # end

  def supported_platform?
    errors.add(:platform, 'not supported') if os.unknown?
    !os.unknown?
  end

  def os
    @os ||= ActiveSupport::StringInquirer.new(os_name)
  end

  def os_name
    case RbConfig::CONFIG['host_os']
    when /linux/
      'linux'
    when /darwin/
      'darwin'
    else
      'unknown'
    end
  end
end