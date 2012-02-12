require 'test/spec/mini'

context "It's test/spec/mini!" do
  setup do
    @name = "Chris"
  end

  setup do
    puts "Stacked setups!"
  end

  teardown do
    @name = nil
  end

  test "with Test::Unit" do
    assert (self.class < Test::Unit::TestCase)
  end

  test "body-less test cases"

  test :symbol_test_names do
    assert true
  end

  xtest "disabled tests" do
    assert disabled!
  end

  context "and of course" do
    test "nested contexts!" do
      assert_equal "Chris", @name
    end
  end
end