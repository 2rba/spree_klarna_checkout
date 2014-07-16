Spree::Core::Engine.routes.draw do
  # Add your extension routes here
  post "/push_uri" => "callback#push_uri"
  get "/confirmation" => "checkout#confirmation"
end
