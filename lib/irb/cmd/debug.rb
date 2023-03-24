require_relative "nop"
require_relative "../debug"

module IRB
  # :stopdoc:

  module ExtendCommand
    class Debug < Nop
      category "Debugging"
      description "Start the debugger of debug.gem."

      BINDING_IRB_FRAME_REGEXPS = [
        '<internal:prelude>',
        binding.method(:irb).source_location.first,
      ].map { |file| /\A#{Regexp.escape(file)}:\d+:in `irb'\z/ }

      def execute(pre_cmds: nil, do_cmds: nil)
        if defined?(DEBUGGER__::SESSION)
          if cmd = pre_cmds || do_cmds
            throw :IRB_EXIT, cmd
          else
            puts "IRB is already running with a debug session."
            return
          end
        end

        unless binding_irb?
          puts "`debug` command is only available when IRB is started with binding.irb"
          return
        end

        unless IRB::Debug.setup
          puts <<~MSG
            You need to install the debug gem before using this command.
            If you use `bundle exec`, please add `gem "debug"` into your Gemfile.
          MSG
          return
        end

        IRB::Debug.insert_debug_break(pre_cmds: pre_cmds, do_cmds: do_cmds)

        # exit current Irb#run call
        throw :IRB_EXIT
      end

      private

      def binding_irb?
        caller.any? do |frame|
          BINDING_IRB_FRAME_REGEXPS.any? do |regexp|
            frame.match?(regexp)
          end
        end
      end
    end

    class DebugCommand < Debug
      def self.category
        "Debugging"
      end

      def self.description
        command_name = self.name.split("::").last.downcase
        "Start the debugger of debug.gem and run its `#{command_name}` command."
      end
    end
  end
end
