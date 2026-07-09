module RefinementArray
  AssertOneError = ::Class.new ::RuntimeError

  refine ::Array do

    def assert_one msg = nil
      return at 0 if 1 == size
      raise ::Common::AssertOneError, "size: #{size}"
    end

    def assert_one_or_less
      return at 0 if 1 >= size
      raise ::Common::AssertOneError "size: #{size}"
    end

  end
end
