require 'hal_presenter'

class Ex3
  class PostSerializer
    extend HALPresenter

    link :item, "/foo"

    link :item do
      "/bar"
    end
  end

  def self.call
    puts PostSerializer.to_hal
  end
end

Ex3.call

# {
#   "_links": {
#     "item": [
#       {
#         "href": "/foo"
#       },
#       {
#         "href": "/bar"
#       }
#     ]
#   }
# }

