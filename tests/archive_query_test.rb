require_relative 'storage_test_case'

require_relative '../model/archive_query'
require_relative '../model/journal_post'

class ArchiveQueryTest < StorageTestCase
  
  def setup
    other = User.new
    other.username = 'other'
    other.save
    
    @all = []
    1.upto(50) do |index|
      p = JournalPost.new
      p.title = index.to_s.rjust(3, '0')
      p.username = index.even? ? 'foo' : 'other'
      p.save
      @all << p
    end
  end
  
  def test_default_to_all
    q = ArchiveQuery.new
    
    assert_equal 'all posts', q.to_s
    assert_equal @all.sort, q.results
  end
  
  def test_query_by_user
    q = ArchiveQuery.from 'foo'
    
    assert_equal 'posts by <strong>foo</strong>', q.to_s
    assert_equal @all.select { |post| post.username == 'foo' }.sort, q.results
  end
  
end