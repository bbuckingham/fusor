#
# Copyright 2015 Red Hat, Inc.
#
# This software is licensed to you under the GNU General Public
# License as published by the Free Software Foundation; either version
# 2 of the License (GPLv2) or (at your option) any later version.
# There is NO WARRANTY for this software, express or implied,
# including the implied warranties of MERCHANTABILITY,
# NON-INFRINGEMENT, or FITNESS FOR A PARTICULAR PURPOSE. You should
# have received a copy of GPLv2 along with this software; if not, see
# http://www.gnu.org/licenses/old-licenses/gpl-2.0.txt.

module Fusor
  class Api::V2::DeploymentsController < Api::V2::BaseController

   before_filter :find_deployment, :only => [:destroy, :show, :update, :deploy]

   def_param_group :deployment do
     param :name, :identifier, :action_aware => true, :required => true, :desc => N_("name of the deployment")
   end

   api :GET, "/deployments", N_("List deployments")
   def index
      respond :collection => Deployment.all
    end

   api :GET, "/deployments/:id", N_("Show a deployment")
   param :id, :identifier, :desc => N_("deployment numeric identifier"), :required => true
   def show
      respond :resource => @deployment
    end

   api :POST, "/deployments", N_("Create a deployment")
   param_group :deployment
   def create
      @deployment = Deployment.create!(params[:deployment])
      respond_for_show :resource => @deployment
    end

   api :PUT, "/deployments/:id", N_("Update a deployment")
   param :id, :identifier, :desc => N_("deployment numeric identifier"), :required => true
   param_group :deployment
   def update
      @deployment.update_attributes!(params[:deployment])
      respond_for_show :resource => @deployment
    end

   api :DELETE, "/deployments/:id", N_("Destroy a deployment")
   param :id, :number, :desc => N_("deployment numeric identifier"), :required => true
   def destroy
      @deployment.destroy
      respond_for_show :resource => @deployment
    end

   api :PUT, "/deployments/:id", N_("Perform a deployment")
   param :id, :identifier, :desc => N_("deployment numeric identifier"), :required => true
   def deploy
      task = async_task(::Actions::Fusor::Deploy, @deployment)
      respond_for_async :resource => task
    end

    def find_deployment
      not_found and return false if params[:id].blank?
      @deployment = Deployment.find(params[:id])
    end
  end
end
