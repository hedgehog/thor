class Thor
  class Task < Struct.new(:name, :description, :usage, :options)

    # A dynamic task that handles method missing scenarios.
    #
    class Dynamic < Task
      def initialize(name)
        super(name.to_s, "A dynamically-generated task", name.to_s)
      end

      def run(instance, args=[])
        unless (instance.methods & [name.to_s, name.to_sym]).empty?
          raise Error, "could not find Thor class or task '#{name}'"
        end
        super
      end
    end

    def initialize(name, description, usage, options=nil)
      super(name.to_s, description, usage, options || {})
    end

    def initialize_copy(other) #:nodoc:
      super(other)
      self.options = other.options.dup if other.options
    end

    def short_description
      description.split("\n").first if description
    end

    # By default, a task invokes a method in the thor class. You can change this
    # implementation to create custom tasks.
    #
    def run(instance, args=[])
      raise UndefinedTaskError, "the '#{name}' task of #{instance.class} is private" unless public_method?(instance)
      instance.send(name, *args)
    rescue ArgumentError => e
      parse_argument_error(instance, e, caller)
    rescue NoMethodError => e
      parse_no_method_error(instance, e)
    end

    # Returns the formatted usage. If a class is given, the class arguments are
    # injected in the usage.
    #
    def formatted_usage(klass=nil, namespace=false, show_options=true)
      formatted = "#{formatted_arguments(klass, namespace)}"
      formatted << " #{formatted_options}" if show_options
      formatted.strip!
      formatted
    end

    # Returns the formatted task name. If a class is given, the namespace
    # is retrived from the class.
    #
    def formatted_task_name(klass=nil, namespace=false)
      nm = "#{name}"
      ns = "#{formatted_namespace(klass, namespace)}"
      if namespace
       "#{ns}#{nm}"
      else
        "#{nm}"
      end
    end

    # Returns the formatted namespace. If a class is given, the namespace
    # is retrived from the class.
    #
    def formatted_namespace(klass=nil, namespace=false)
      if namespace.is_a?(String)
        "#{namespace}:"
      elsif namespace
        "#{klass.namespace.gsub(/^default/,'')}:"
      else
        ""
      end
    end

    # Injects the class arguments into the task usage.
    #
    def formatted_arguments(klass, namespace=false)
      usg = if klass && !klass.arguments.empty?
        usage.to_s.gsub(/^#{name}/) do |match|
          match << " " << klass.arguments.map{ |a| a.usage }.join(' ')
        end
      else
        usage.to_s
      end
      if namespace
        ns = "#{formatted_namespace(klass, namespace)}"
        ns << usg # don't use << you'll clobber the help text output
      else
        usg
      end
    end

    # Returns the options usage for this task.
    #
    def formatted_options
      @formatted_options ||= options.map{ |_, o| o.usage }.sort.join(" ")
    end

    protected

      # Given a target, checks if this class name is not a private/protected method.
      #
      def public_method?(instance) #:nodoc:
        collection = instance.private_methods + instance.protected_methods
        (collection & [name.to_s, name.to_sym]).empty?
      end

      # Clean everything that comes from the Thor gempath and remove the caller.
      #
      def sans_backtrace(backtrace, caller) #:nodoc:
        dirname = /^#{Regexp.escape(File.dirname(__FILE__))}/
        saned  = backtrace.reject { |frame| frame =~ dirname }
        saned -= caller
      end

      def parse_argument_error(instance, e, caller) #:nodoc:
        backtrace = sans_backtrace(e.backtrace, caller)
        tn = "#{formatted_task_name(instance.class, true)}"
        usg = "#{formatted_usage(instance.class, true, true)}"
        msg = "#{tn} called incorrectly. "

        if backtrace.empty? && e.message =~ /wrong number of arguments/
          no_match = !(instance.shell.base.class.is_a?(instance.class))
          if instance.is_a?(Thor::Group) or no_match
            msg << "Were required arguments provided? #{usg}"
            raise e, msg
          else
            msg << "Call as '#{usg}'"
            raise InvocationError, msg
          end
        else
          raise e
        end
      end

      def parse_no_method_error(instance, e) #:nodoc:
        if e.message =~ /^undefined method `#{name}' for #{Regexp.escape(instance.to_s)}$/
          raise UndefinedTaskError, "The #{instance.class.namespace} namespace " <<
                                    "doesn't have a '#{name}' task"
        else
          raise e
        end
      end

  end
end
