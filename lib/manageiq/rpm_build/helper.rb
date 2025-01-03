# rubocop:disable Rails/Exit Rails/Output Style/SpecialGlobalVars

module ManageIQ
  module RPMBuild
    module Helper
      private

      def where_am_i
        puts "\n ---> #{self.class.name}##{caller_locations(1..1).first.base_label}".cyan.bold
      end

      def shell_cmd(cmd, env = {})
        puts_shell_cmd(cmd, env)
        exit($?.exitstatus || 1) unless system(env, cmd.to_s)
      end

      def shell_cmd_in_venv(cmd, venv, env = {})
        puts_shell_cmd(cmd, env, "(venv)")
        cmd = "source #{venv.join("bin/activate")}; #{cmd}; deactivate"
        exit($?.exitstatus || 1) unless system(env, cmd.to_s)
      end

      def puts_shell_cmd(cmd, env, prefix = "")
        prefix << " " unless prefix.empty?

        env = env.to_a.map { |e| e.join("=") }.join(" ")
        env << " " unless env.empty?

        puts "\n ---> #{prefix}#{env}#{cmd}".yellow.bold
      end
    end
  end
end

# rubocop:enable Rails/Exit Rails/Output Style/SpecialGlobalVars
