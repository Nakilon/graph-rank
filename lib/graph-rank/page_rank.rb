# Brin, S.; Page, L. (1998). "The anatomy of 
# a large-scale hypertextual Web search engine". 
# Computer Networks and ISDN Systems 30: 107–117.
class GraphRank::PageRank

  # Initialize with default damping and convergence.
  # A maximum number of iterations can also be supplied
  # (default is no maximum, i.e. iterate until convergence).
  def initialize(damping=nil, convergence=nil, max_it=10000)
    damping ||= 0.85; convergence ||= 0.0000001
    if damping <= 0 or damping > 1
      raise 'Invalid damping factor.'
    elsif convergence < 0 or convergence > 1
      raise 'Invalid convergence factor.'
    end
    @damping, @convergence, @max_it = damping, convergence, max_it
    @graph, @outlinks, @nodes, @weights = {}, {}, {}, {}
    
    #flags
    @doPageRank = true
    @doGravityRank = false
    if @doGravityRank
      puts('doing GRAVITY RANK')
      @doPageRank = false
      @max_it = 2
    end
  end

  # Add a node to the graph.
  def add(source, dest, weight=1.0, sourcePriorWeight = 0.15, destPriorWeight = 0.15)
    
    #flag
    @allowSelfEdges = true
    #flag
    
    if not @allowSelfEdges
      return false if source == dest
    end
    @outlinks[source] ||= 0.0
    @graph[dest] ||= []
    
    #avoid establishing link if it already exists
    if @graph[dest].include? source
        puts("in page_rank.add link already exists between #{source} and #{dest}")
        return true
    end
    
    @graph[dest] << source
    @outlinks[source] += 1.0
    @nodes[source] = sourcePriorWeight #0.15
    @nodes[dest] = destPriorWeight # 0.15
    @weights[source] ||= {}
    @weights[source][dest] = weight
  end

  # Iterates the PageRank algorithm
  # until convergence is reached.
  def calculate
    puts("in page_rank#calculate")
    done = false
    numiterations = 0
    until done
      numiterations += 1      
      break if @max_it == 0
      #puts("right before iteration")
      new_nodes = iteration
      #puts("right after iteration")
      #printGraph new_nodes #for debug
      done = convergence(new_nodes)
      @nodes = new_nodes
      @max_it -= 1
    end
    puts("numiterations = #{numiterations}")
    @nodes.sort_by {|k,v|v}.reverse
  end
  
  def printGraph new_nodes = nil, logFile = nil

      puts("printing graph:")
      if not logFile.nil?
        logFile.puts("printing graph:")
      end
      @graph.each do |node,links|
          if not new_nodes.nil?  and new_nodes.has_key? node
            puts("#{node} (#{new_nodes[node]}) <- #{links}")
            if not logFile.nil?
              logFile.puts("#{node} (#{new_nodes[node]}) <- #{links}")
            end
          else
            puts("#{node} <- #{links}")
            if not logFile.nil?
              logFile.puts("#{node} <- #{links}")
            end
          end
          for link in links
            weight = @weights[link][node]
            puts("#{link} edge weight = #{weight}")
            if not logFile.nil?
              logFile.puts("#{link} edge weight = #{weight}")
            end
          end
      end
      puts("--------------------")
  end

  private

  # Performs one iteration to calculate
  # the PageRank ranking for all nodes.
  def iteration
    #puts('in iteration')
    new_nodes = {}
    @graph.each do |node,links|
      #puts("node= #{node}, links = #{links}")
      
      score = links.map do |id|
        if @doPageRank
          @nodes[id] / @outlinks[id] * @weights[id][node] #straight pagerank score
        elsif @doGravityRank #do gravityRank
          @nodes[id] * @weights[id][node] #not dividing by out link just like a planet's gravity is the same regardless of how many other planets are around it > note that maxt iter needs to be small for this as it wouldn't converge
        end  
      end.inject(:+)
      
      new_nodes[node] = (1-@damping/
      @nodes.size) + @damping * score
    end
    new_nodes
  end

  # Check for convergence.
  def convergence(current)
    diff = {}
    @nodes.each do |k,v|
      #puts("k = #{k}")      
      diff[k] = current[k] - @nodes[k]
    end
    total = 0.0
    diff.each { |k,v| total += diff[k] * v }
    Math.sqrt(total/current.size) < @convergence
  end

end