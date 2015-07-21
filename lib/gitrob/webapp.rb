module Gitrob
  class WebApp < Sinatra::Base
    set :logging, false
    set :sessions, false
    set :app_file, __FILE__
    set :root, File.expand_path("#{File.dirname(__FILE__)}/../../")
    set :public_folder, Proc.new { File.join(root, "public") }
    set :views, Proc.new { File.join(root, "views") }
    set :run, Proc.new { false }

    helpers do
      HUMAN_PREFIXES = %W(TB GB MB KB B).freeze

      alias_method :h, :escape_html

      def number_to_human_size(number)
        s = number.to_f
        i = HUMAN_PREFIXES.length - 1
        while s > 512 && i > 0
          i -= 1
          s /= 1024
        end
        ((s > 9 || s.modulo(1) < 0.1 ? '%d' : '%.1f') % s) + ' ' + HUMAN_PREFIXES[i]
      end

      def format_path(path)
        dirname  = File.dirname(path)
        basename = File.basename(path)
        if dirname == '.'
          "<strong>#{h basename}</strong>"
        else
          "#{h dirname}/<strong>#{h basename}</strong>"
        end
      end
    end

    before do
      response.headers['Content-Security-Policy'] = "default-src *; script-src 'self'; style-src 'self' 'unsafe-inline'; font-src 'self'; connect-src 'self'"
      response.headers['X-Content-Security-Policy'] = "default-src *; script-src 'self'; style-src 'self' 'unsafe-inline'; font-src 'self'; connect-src 'self'"
      response.headers['X-WebKit-CSP'] = "default-src *; script-src 'self'; style-src 'self' 'unsafe-inline'; font-src 'self'; connect-src 'self'"
    end

    get '/' do
      if params['operation'] == 'scan'
         Gitrob::scan_org(params['orgname'], 2, 'new')
      else
         @orgs = Gitrob::Organization.all(:order => [:created_at.desc])
         erb :index
      end
    end

    get '/orgs/:id' do
      @org = Gitrob::Organization.get(params['id'])
      @blobs_with_findings = @org.blobs.all(:findings_count.gt => 0)
      @repos = @org.repos.all(:order => [:owner_name, :name])

      if params['operation'] == 'delete'
        @org.destroy
        @orgs = Gitrob::Organization.all(:order => [:created_at.desc])
      elsif params['operation'] == 'update'
        Gitrob::scan_org(@org.username, 3, 'update', params['id'])
      end
      erb :organization
    end

    get '/repos/:id' do
      @repo = Gitrob::Repo.get(params['id'])
      erb :repository
    end

    get '/ajax/users/:username' do
      if params['type'] == 'org'
        @user  = Gitrob::Organization.first(:name => params['username'])
        @repos = @user.repos.all(:user => nil)
      else
        @user  = Gitrob::User.first(:username => params['username'])
        @repos = @user.repos.all
      end
      erb :user, :layout => false
    end

    get '/ajax/blobs/:id' do
      @blob = Gitrob::Blob.get(params['id'])
      if params['blobstat'].nil?
         @blob.update(:status => 'unknown')
      else
         @blob.update(:status => params['blobstat'])
      end
      erb :blob, :layout => false
    end
  end
end
