module ManageIQ
  module RPMBuild
    module Helper
      def where_am_i
        puts "\n ---> #{self.class.name}##{caller_locations(1..1).first.base_label}".cyan.bold
      end

      def shell_cmd(cmd)
        puts "\n ---> #{cmd}".yellow.bold
        exit($?.exitstatus || 1) unless system(env, cmd.to_s)
      end
    end
  end
end
