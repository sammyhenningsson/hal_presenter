require 'hal_presenter'
require 'ostruct'

class Ex2
  class PostSerializer
    extend HALPresenter

    link :self do
      "/posts/#{resource.id}"
    end
  end


  def self.call
    post = OpenStruct.new(id: 5)
    puts PostSerializer.to_hal(post)
  end
end

Ex2.call

# {
#   "_links": {
#     "self": {
#       "href": "/posts/5"
#     }
#   }
# }
