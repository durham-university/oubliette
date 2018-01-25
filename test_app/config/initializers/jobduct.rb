Jobduct.set_http_authenticator do |conn, host, path|
  conn.basic_auth("apiuser", "apiuser")
end