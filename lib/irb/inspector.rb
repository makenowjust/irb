#
#   irb/inspector.rb - inspect methods
#   	$Release Version: 0.9.6$
#   	$Revision: 1.19 $
#   	$Date: 2002/06/11 07:51:31 $
#   	by Keiju ISHITSUKA(keiju@ruby-lang.org)
#
# --
#
#
#

module IRB # :nodoc:


  # Convenience method to create a new Inspector, using the given +inspect+
  # proc, and optional +init+ proc and passes them to Inspector.new
  #
  #     irb(main):001:0> ins = IRB::Inspector(proc{ |v| "omg! #{v}" })
  #     irb(main):001:0> IRB.CurrentContext.inspect_mode = ins # => omg! #<IRB::Inspector:0x007f46f7ba7d28>
  #     irb(main):001:0> "what?" #=> omg! what?
  #
  def IRB::Inspector(inspect, init = nil)
    Inspector.new(inspect, init)
  end

  # An irb inspector
  #
  # In order to create your own custom inspector there are two things you
  # should be aware of:
  #
  # Inspector uses #inspect_value, or +inspect_proc+, for output of return values.
  #
  # This also allows for an optional #init+, or +init_proc+, which is called
  # when the inspector is activated.
  #
  # Knowing this, you can create a rudimentary inspector as follows:
  #
  #     irb(main):001:0> ins = IRB::Inspector.new(proc{ |v| "omg! #{v}" })
  #     irb(main):001:0> IRB.CurrentContext.inspect_mode = ins # => omg! #<IRB::Inspector:0x007f46f7ba7d28>
  #     irb(main):001:0> "what?" #=> omg! what?
  #
  class Inspector
    # Creates a new inspector object, using the given +inspect_proc+ when
    # output return values in irb.
    def initialize(inspect_proc, init_proc = nil)
      @init = init_proc
      @inspect = inspect_proc
    end

    # Proc to call when the inspector is activated, good for requiring
    # dependant libraries.
    def init
      @init.call if @init
    end

    # Proc to call when the input is evaluated and output in irb.
    def inspect_value(v)
      @inspect.call(v)
    end
  end

  # Default inspectors available to irb, this includes:
  #
  # +:pp+::       Using Kernel#pretty_inspect
  # +:yaml+::     Using YAML.dump
  # +:marshal+::  Using Marshal.dump
  INSPECTORS = {}

  # Determines the inspector to use where +inspector+ is one of the keys passed
  # during inspector definition.
  def INSPECTORS.keys_with_inspector(inspector)
    select{|k,v| v == inspector}.collect{|k, v| k}
  end

  # Example
  #
  #     INSPECTORS.def_inspector(key, init_p=nil){|v| v.inspect}
  #     INSPECTORS.def_inspector([key1,..], init_p=nil){|v| v.inspect}
  #     INSPECTORS.def_inspector(key, inspector)
  #     INSPECTORS.def_inspector([key1,...], inspector)
  def INSPECTORS.def_inspector(key, arg=nil, &block)
#     if !block_given?
#       case arg
#       when nil, Proc
# 	inspector = IRB::Inspector(init_p)
#       when Inspector
# 	inspector = init_p
#       else
# 	IRB.Raise IllegalParameter, init_p
#       end
#       init_p = nil
#     else
#       inspector = IRB::Inspector(block, init_p)
#     end

    if block_given?
      inspector = IRB::Inspector(block, arg)
    else
      inspector = arg
    end

    case key
    when Array
      for k in key
	def_inspector(k, inspector)
      end
    when Symbol
      self[key] = inspector
      self[key.to_s] = inspector
    when String
      self[key] = inspector
      self[key.intern] = inspector
    else
      self[key] = inspector
    end
  end

  INSPECTORS.def_inspector([false, :to_s, :raw]){|v| v.to_s}
  INSPECTORS.def_inspector([true, :p, :inspect]){|v|
    begin
      v.inspect
    rescue NoMethodError
      puts "(Object doesn't support #inspect)"
    end
  }
  INSPECTORS.def_inspector([:pp, :pretty_inspect], proc{require "pp"}){|v| v.pretty_inspect.chomp}
  INSPECTORS.def_inspector([:yaml, :YAML], proc{require "yaml"}){|v|
    begin
      YAML.dump(v)
    rescue
      puts "(can't dump yaml. use inspect)"
      v.inspect
    end
  }

  INSPECTORS.def_inspector([:marshal, :Marshal, :MARSHAL, Marshal]){|v|
    Marshal.dump(v)
  }
end





