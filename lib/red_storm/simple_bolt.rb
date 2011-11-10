module RedStorm

  class SimpleBolt

    # DSL class mthods

    def self.output_fields(*fields)
      @fields = fields.map(&:to_s)
    end

    def self.on_tuple(*args, &tuple_block)
      options = args.last.is_a?(Hash) ? args.pop : {}
      method_name = args.first

      self.execute_options.merge!(options)
      @tuple_block = block_given? ? tuple_block : lambda {|tuple| self.send(method_name, tuple)}
    end

    def self.on_init(method_name = nil, &init_block)
      @init_block = block_given? ? init_block : lambda {self.send(method_name)}
    end

    def emit(*values)
      @collector.emit(Values.new(*values)) 
    end

    def ack(tuple)
      @collector.ack(tuple)
    end

    # Bolt interface

    def execute(tuple)
      if (output = instance_exec(tuple, &self.class.tuple_block)) && self.class.emit?
        values = [output].flatten
        self.class.anchor? ? @collector.emit(tuple, Values.new(*values)) : emit(*values)
        @collector.ack(tuple) if self.class.ack?
      end
    end

    def prepare(config, context, collector)
      @collector = collector
      @context = context
      @config = config
      instance_exec(&self.class.init_block)
    end

    def declare_output_fields(declarer)
      declarer.declare(Fields.new(self.class.fields))
    end

    private

    def self.fields
      @fields
    end

    def self.tuple_block
      @tuple_block ||= lambda {}
    end

    def self.init_block
      @init_block ||= lambda {}
    end

    def self.execute_options
      @execute_options ||= {:emit => true, :ack => false, :anchor => false}
    end

    def self.emit?
      !!self.execute_options[:emit]
    end

    def self.ack?
      !!self.execute_options[:ack]
    end

    def self.anchor?
      !!self.execute_options[:anchor]
    end

  end

end