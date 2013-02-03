require 'dropbox_sdk'

# This is an example of a Rails 3 controller that authorizes an application
# and then uploads a file to the user's Dropbox.

# You must set these
APP_KEY = "84vrmpv7mfdfzh7"
APP_SECRET = "9tmzxpts5naj2qt"
ACCESS_TYPE = :app_folder #The two valid values here are :app_folder and :dropbox
                          #The default is :app_folder, but your application might be
                          #set to have full :dropbox access.  Check your app at
                          #https://www.dropbox.com/developers/apps


# Examples routes for config/routes.rb  (Rails 3)
#match 'db/authorize', :controller => 'db', :action => 'authorize'
#match 'db/upload', :controller => 'db', :action => 'upload'

class DbController < ApplicationController
    def authorize
        if not params[:oauth_token] then
            dbsession = DropboxSession.new(APP_KEY, APP_SECRET)

            session[:dropbox_session] = dbsession.serialize #serialize and save this DropboxSession

            #pass to get_authorize_url a callback url that will return the user here
            redirect_to dbsession.get_authorize_url url_for(:action => 'authorize')
        else
            # the user has returned from Dropbox
            dbsession = DropboxSession.deserialize(session[:dropbox_session])
            dbsession.get_access_token  #we've been authorized, so now request an access_token
            session[:dropbox_session] = dbsession.serialize

            redirect_to :action => 'index'
        end
    end

    def index
    end

    def stream
        # Check if user has no dropbox session...re-direct them to authorize
        return redirect_to(:action => 'authorize') unless session[:dropbox_session]

        dbsession = DropboxSession.deserialize(session[:dropbox_session])
        client = DropboxClient.new(dbsession, ACCESS_TYPE) #raise an exception if session not authorized
        info = client.account_info # look up account information


        metadata = client.metadata('/')

        contents= client.get_file(metadata["contents"].sample["path"], rev=metadata["contents"].sample["rev"])
        render text: contents
    end
end
