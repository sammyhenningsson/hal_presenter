require 'hal_presenter'

class Ex1
  class PostSerializer
    extend HALPresenter
    link :self, '/posts/1'
  end

  def self.call
    puts PostSerializer.to_hal
  end
end

Ex1.call

# {
#   "_links": {
#     "self": {
#       "href": "/posts/1"
#     }
#   }
# }
