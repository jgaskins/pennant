require "http"

require "./pennant"

class Pennant::Web
  include HTTP::Handler

  def initialize(mount_at @path : String)
  end

  def call(context)
    request = context.request
    response = context.response
    response.headers["content-type"] = "text/html"

    case {request.method, request.path}
    when {"GET", @path}
      homepage response
    when {"POST", @path}
      create request, response
    when {"DELETE", %r<\A#{Regex.escape(@path)}>}
      delete request, response
    else
      call_next context
    end
  end

  def homepage(response)
    {% begin %}
      ECR.embed "{{__DIR__.id}}/templates/homepage.ecr", response
    {% end %}
  end

  def create(request, response)
    if body = request.body
      pp URI::Params.parse body.gets_to_end
    else
      response.status = :bad_request
      response << "<h1>Must provide a request body</h1>"
    end
  end

  def delete(request, response)

  end

  def not_found(response)
    response.status = :not_found
    response << "<h1>Not found</h1>"
  end
end
