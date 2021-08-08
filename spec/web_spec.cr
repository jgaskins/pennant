require "./spec_helper"

require "../src/web"

describe Pennant::Web do
  it "lol idk" do
    app = Pennant::Web.new(mount_at: "/")

    response = make_server.get("/")

    response.body.should contain "Pennant"
    puts response.body
  end
end

private class TestServer
  include HTTP::Handler

  def initialize(@next : HTTP::Handler)
    @io = IO::Memory.new
  end

  def call(context)
    call_next context

    context.response.close

    HTTP::Client::Response.from_io @io.rewind
  end

  def get(path, headers = HTTP::Headers.new, body = nil)
    call make_context(
      method: "GET",
      path: path,
      headers: headers,
      body: body,
      io: @io,
    )
  end

  private def make_context(method : String = "GET", path : String = "/", headers = HTTP::Headers.new, body = nil, io = IO::Memory.new)
    request = HTTP::Request.new(
      method: method,
      resource: path,
      headers: headers,
      body: body,
    )

    response = HTTP::Server::Response.new(io)

    HTTP::Server::Context.new(request, response)
  end
end

private def make_server(mount_at = "/")
  TestServer.new(Pennant::Web.new(mount_at: "/"))
end
