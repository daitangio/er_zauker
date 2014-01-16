defmodule SparseSetTest do
  use ExUnit.Case

	# Test cas eimport everything
	import SparseSet, only: [ :all ]

  test "the truth" do
    assert(true)
  end

	test "simple new" do
		s= SparseSet.SSet.new
		assert (s != nil)
	end

	test "empty set is empty" do
		s =SparseSet.SSet.new()
		assert SparseSet.Sparse.isMember?(s, 0) ==false
	end

	test "simple add" do
		s=SparseSet.SSet.new
		IO.puts inspect s
		s2=SparseSet.Sparse.add( s, 42)		
		#s2=s.add(42)
		assert SparseSet.Sparse.isMember?(s2,42) == true
	end
end
