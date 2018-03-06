Jobduct.set_http_authenticator do |conn, host, path|
  conn.basic_auth("apiuser", "apiuser")
end

Jobduct.runner_adapter = Jobduct::ActiveJobAdapter.new