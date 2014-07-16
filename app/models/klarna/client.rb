require 'digest/sha2'
require 'base64'
require 'faraday'

class Klarna::Client
  attr_accessor :shared_secret, :test_mode

  def initialize(shared_secret, test_mode)
    self.shared_secret = shared_secret
    self.test_mode = test_mode
  end


  def create(data)
    response = post(nil,data)
    id = response.headers['Location'].split('/').last
    fetch(id)
  end

  def fetch(id)
    response = https_connection.get do |req|
      req.url "/checkout/orders/#{id}"

      req.headers['Authorization']   = "Klarna #{sign_payload}"
      req.headers['Accept']          = 'application/vnd.klarna.checkout.aggregated-order-v2+json'
      req.headers['Accept-Encoding'] = ''
    end
    handle_status_code(response.status, response.body)

    JSON.parse(response.body)
  end

  def post(order_id,data)
    path  = "/checkout/orders"
    path += "/#{order_id}" if order_id

    request_body = data.reject { |k, v| v.nil? }.to_json
    response = https_connection.post do |req|
      req.url path

      req.headers['Authorization']   = "Klarna #{sign_payload(request_body)}"
      req.headers['Accept']          = 'application/vnd.klarna.checkout.aggregated-order-v2+json',
      req.headers['Content-Type']    = 'application/vnd.klarna.checkout.aggregated-order-v2+json'
      req.headers['Accept-Encoding'] = ''

      req.body = request_body
      p request_body
    end
    handle_status_code(response.status, response.body)
    response
  end


  private
  def host
    if test_mode
      'https://checkout.testdrive.klarna.com'
    else
      'https://checkout.klarna.com'
    end
  end

  def handle_status_code(code, msg = nil, &blk)
    case Integer(code)
    when 200, 201
      yield if block_given?
    when 400
      raise Klarna::BadRequest.new(msg)
    when 401
      raise Klarna::UnauthorizedException.new(msg)
    when 403
      raise Klarna::ForbiddenException.new(msg)
    when 404
      raise Klarna::NotFoundException.new(msg)
    when 405
      raise Klarna::MethodNotAllowedException.new(msg)
    when 406
      raise Klarna::NotAcceptableException.new(msg)
    when 415
      raise Klarna::UnsupportedMediaTypeException.new(msg)
    when 500
      raise Klarna::InternalServerErrorException.new(msg)
    else
      raise Klarna::Exception.new(msg)
    end
  end

  def https_connection
    @https_connection ||= Faraday.new(url: host)
  end

  def sign_payload(request_body = '')
    payload = "#{request_body}#{shared_secret}"
    Digest::SHA256.base64digest(payload)
  end


end

class Klarna::Exception < StandardError
end

class Klarna::BadRequest < Klarna::Exception
end

class Klarna::UnauthorizedException < Klarna::Exception
end

class Klarna::ForbiddenException < Klarna::Exception
end

class Klarna::NotFoundException < Klarna::Exception
end

class Klarna::MethodNotAllowedException < Klarna::Exception
end

class Klarna::NotAcceptableException < Klarna::Exception
end

class Klarna::UnsupportedMediaTypeException < Klarna::Exception
end

class Klarna::InternalServerErrorException < Klarna::Exception
end
