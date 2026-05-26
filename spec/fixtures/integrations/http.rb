# frozen_string_literal: true

require "webmock"

WebMock.enable!
WebMock.after_request do |req, response|
  data_item = Sniffer::DataItem.new
  data_item.request = Sniffer::DataItem::Request.new(
    host: req.uri.host,
    method: req.method,
    query: req.uri.path,
    headers: {}
  )
  Sniffer.store(data_item)
  data_item.response = Sniffer::DataItem::Response.new(
    status: 200,
    body: "",
    headers: {},
    timing: rand
  )
  Sniffer.notify_response(data_item)
end

WebMock.disable_net_connect!

class SomeClient
  include WebMock::API

  def initialize
    stub_request(:any, "http://ruby-lang.org")
  end

  def perform
    Net::HTTP.get(URI("http://ruby-lang.org"))
  end
end

SomeClient.new.perform
