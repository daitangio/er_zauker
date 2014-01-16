defmodule SparseSet do
	@moduledoc	"""
For a complete explanation see
http://research.swtch.com/sparse

 Operation 	Bit Vector 	Sparse set
 is-member 	O(1) 	      O(1)
 add-member O(1) 	      O(1)
 clear-set 	O(m) 	      O(1)
  iterate 	O(m) 	      O(n)
  """

	defrecord SSet, dense: {}, sparse: {}, n: 0 

	defprotocol Sparse do
		def isMember?(set,integer)
		def add(set,i)
		# def clear(set)
		# def iterate(set,f)

	end

	# Protocol implementation for SSet
	defimpl Sparse, for: SSet do

		

		def isMember?(set,i) do
			IO.puts "isMember? set=#{inspect(set)} i=#{i}"
			if set.n==0 do
				false
			else
			
				sparse_i= elem set.sparse,i 
				IO.puts "sparse_i: #{sparse_i}"

		    #return sparse[i] < n && dense[sparse[i]] == i
		    (elem(set.sparse , i)) < set.n and ((elem set.dense, elem(set.sparse,i)) == i)
			end
		end
	 def add(set,i) do 
		 IO.puts "Adding..."
		  # Ensure enough size...
		  #dense: {}, sparse: {}, n: 0 
		  #SSet.new(dense: s.dense
		      #dense[n] = i
					#sparse[i] = n
					#n++
	    SSet.new()
	 end
	end
end
