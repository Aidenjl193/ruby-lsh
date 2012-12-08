require 'gsl'

module LSH

  class Index

    def initialize(dim, k, w, l)
      @random = GSL::Rng.alloc # default seed of 0
      @window = w
      @dim = dim
      @number_of_random_vectors = k
      @number_of_independent_projections = l
      @projections = generate_projections(dim, k, l)
      @buckets = []
      l.times { |i| @buckets << {} }
    end

    def add(vector)
      hashes(vector).each_with_index do |hash, i|
        if @buckets[i].has_key? hash
          @buckets[i][hash] << vector
        else
          @buckets[i][hash] = [vector]
        end
      end
    end

    def query(vector)
      results = {}
      hashes(vector).each_with_index do |hash, i|
        if @buckets[i].has_key? hash
          @buckets[i][hash].each do |result|
            if results.has_key? result
              results[result] += 1
            else
              results[result] = 1
            end
          end
        end
      end
      (results.sort_by { |k, v| v }).reverse.map { |r| r[0] }
    end

    def hashes(vector)
      hashes = []
      @projections.each do |projection|
        hashes << hash(vector, projection)
      end
      hashes
    end

    def hash(vector, projection)
      r = GSL::Rng.alloc
      hash = []
      projection.each do |random_vector|
        dot_product = vector * random_vector.col
        hash << ((dot_product + @random.uniform * @window) / @window).floor
      end
      hash
    end

    def generate_projections(dim, k, l)
      projections = []
      l.times do |i|
        projections << generate_projection(dim, k)
      end
      projections
    end

    def generate_projection(dim, k)
      vectors = []
      k.times do |i|
        vectors << random_vector(dim)
      end
      vectors
    end

    def random_vector(dim)
      @random.gaussian(1, dim)
    end

  end

end