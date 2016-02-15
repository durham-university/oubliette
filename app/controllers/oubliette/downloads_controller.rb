module Oubliette
  class DownloadsController < Oubliette::ApplicationController
    # This class is largely based on Hydra::Conroller::DownloadBehaviour.
    # It's replicated here so we don't need to depend on hydra-head and all it's
    # dependencies just for the download behaviour.

    before_action :authenticate_user!
    before_filter :authorize_download!

    def authenticate_user!(opts={})
      authenticate_api_user
      super(opts) unless warden.user
    end

    def authenticate_api_user
      if Oubliette.config['api_debug'] && params['api_debug']
        # This is for debugging and development only. Allows full access simply
        # by setting the api_debug parameter in the request.
        warden.request.env['devise.skip_trackable'] = true
        warden.set_user(User.new(roles: ['api']))
        true
      else
        false
      end
    end

    def show
      if file.new_record?
        render_404
      else
        send_content
      end
    end

    protected

      def render_404
        respond_to do |format|
          format.html { render :file => "#{Rails.root}/public/404", :layout => false, :status => :not_found }
          format.any  { head :not_found }
        end
      end

      def asset_param_key
        :id
      end

      def authorize_download!
        authorize! :download, file
      end

      def file
        @file ||= load_file
      end

      def asset
        @asset ||= ActiveFedora::Base.find(params[asset_param_key])
      end

      def load_file
        file_ref = params.fetch(:file, :content)
        if [:content, :ingestion_log, :preservation_log].include?(file_ref.to_sym)
          file = asset.send(file_ref.to_sym)
#          if params[:version]
#            file = file.versions.all.find do |v| v.label==params[:version] end
#          end
#          file
        else
          raise "Invalid file ref"
  #        asset.files.to_a.find do |file| file.original_name==file_ref end
        end
      end

      def send_content
        response.headers['Accept-Ranges'] = 'bytes'

        if request.head?
          content_head
        elsif request.headers['HTTP_RANGE']
          send_range
        else
          send_file_contents
        end
      end

      def file_name
        file.original_name || (asset.respond_to?(:label) && asset.label) || file.id
      end

      def content_head
        response.headers['Content-Length'] = file.size
        response.headers['Content-Type'] = file.mime_type
        head :ok
      end

      def send_range
        _, range = request.headers['HTTP_RANGE'].split('bytes=')
        from, to = range.split('-').map(&:to_i)
        to = file.size - 1 unless to
        length = to - from + 1
        response.headers['Content-Range'] = "bytes #{from}-#{to}/#{file.size}"
        response.headers['Content-Length'] = "#{length}"
        self.status = 206
        prepare_file_headers
        stream_body file.stream(request.headers['HTTP_RANGE'])
      end

      def send_file_contents
        self.status = 200
        prepare_file_headers
        stream_body file.stream
      end

      def prepare_file_headers
        send_file_headers!({ disposition: 'inline', type: file.mime_type, filename: file_name })
        response.headers['Content-Type'] = file.mime_type
        response.headers['Content-Length'] ||= file.size.to_s
        # Prevent Rack::ETag from calculating a digest over body
        response.headers['Last-Modified'] = asset.modified_date.utc.strftime("%a, %d %b %Y %T GMT")
        self.content_type = file.mime_type
      end

      private

        def stream_body(iostream)
          iostream.each do |in_buff|
            response.stream.write in_buff
          end
        ensure
          response.stream.close
        end

  end
end
