module GoaModelGen
  class GolangHelper

    PARTITION_PATTERNS = [
      /\A[^\.\/]+(?:\/.+)?\z/,
      /\Agopkg\.in\//,
      /\Agolang\.org\//,
      /\Agoogle\.golang\.org\//,
      /\Agithub\.com\//,
    ]

    def partition(paths)
      groups = paths.group_by do |path|
        PARTITION_PATTERNS.index{|ptn| ptn =~ path} || PARTITION_PATTERNS.length
      end
      groups.keys.sort.map{|k| groups[k].sort }
    end
  end
end
