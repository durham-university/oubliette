module Oubliette
  class ResqueAdmin
    def self.matches?(request)
      current_user = request.env['warden'].user
      return current_user && current_user.is_admin?
    end
  end
end
