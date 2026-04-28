module Common
  AssertOneError = ::Class.new ::RuntimeError

  module RefinementArray
    refine ::Array do

      def assert_one msg = nil
        return at 0 if 1 == size
        raise ::Common::AssertOneError, "size: #{size.to_s}#{
          if msg
            ", #{msg}"
          elsif block_given?
            ", #{yield self}"
          end
        }"
      end

    end
  end

end
