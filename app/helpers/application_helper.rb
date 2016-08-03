module ApplicationHelper
  def tag_cloud(tags, classes)
    # max = tags.sort_by(&:count).last
    
    # There's no need to sort the array only to pick the largest element. Oren Dobzinski
    max = tags.max_by(&:count)
    tags.each do |tag|
      index = tag.count.to_f / max.count * (classes.size - 1)
      yield(tag, classes[index.round])
    end
  end
end