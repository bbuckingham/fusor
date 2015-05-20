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

module Actions
  module Fusor
    module Deployment
      class RhevEnginePuppetRun < Actions::Base
        def humanized_name
          _("Perform a puppet run for the RHEV engine.")
        end

        def plan(deployment)
          sequence do
            plan_self(:deployment_id => deployment.id)
            plan_action(::Actions::Fusor::Host::WaitUntilReady, deployment.rhev_engine_host)
            plan_action(::Actions::Fusor::Host::Deploy, deployment.rhev_engine_host)
          end
        end

        private

        def run
          deployment = ::Fusor::Deployment.find(input[:deployment_id])
          apply_deployment_parameter_overrides(deployment)
        end

        def apply_deployment_parameter_overrides(deployment)
          deployment_overrides =
              [
                  {
                      :hostgroup_name => "RHEV-Engine",
                      :puppet_classes =>
                          [
                              {
                                  :name => "ovirt::engine::config",
                                  :parameters =>
                                      [
                                          { :name => "hosts_addresses", :value => host_addresses(deployment, hostgroup) },
                                          # Setting root password based upon the deployment vs the hostgroup.  This is
                                          # necessary because the puppet parameter needs to store it in clear text and
                                          # the hostgroup stores it using one-time encryption.
                                          { :name => "root_password", :value => deployment.rhev_root_password },
                                          { :name => "cluster_name", :value => deployment.rhev_cluster_name },
                                          { :name => "storage_name", :value => deployment.rhev_storage_name },
                                          { :name => "storage_address", :value => deployment.rhev_storage_address },
                                          { :name => "storage_type", :value => deployment.rhev_storage_type },
                                          { :name => "storage_path", :value => deployment.rhev_share_path },
                                          { :name => "cpu_type", :value => deployment.rhev_cpu_type }
                                      ]
                              },
                              {
                                  :name => "ovirt::engine::setup",
                                  :parameters =>
                                      [
                                          { :name => "storage_type", :value => deployment.rhev_storage_type },
                                          { :name => "admin_password", :value => deployment.rhev_engine_admin_password }
                                      ]
                              }
                          ]
                  }
              ]

          hostgroup = find_hostgroup(deployment, "RHEV-Engine")

          # Check if the host group has some overrides specified for this deployment.
          # If it does, set them for the host group.
          if overrides = deployment_overrides.find{ |hg| hg[:hostgroup_name] == hostgroup.name }
            overrides[:puppet_classes].each do |pclass|
              puppet_class = Puppetclass.where(:name => pclass[:name]).
                  joins(:environment_classes).
                  where("environment_classes.environment_id in (?)", hostgroup.environment_id).first

              pclass[:parameters].each do |parameter|
                hostgroup.set_param_value_if_changed(puppet_class, parameter[:name], parameter[:value])
              end
            end
          end
        end

        def host_addresses(deployment, hostgroup)
          addresses = deployment.discovered_hosts.inject([]) do |result, host|
            if host.name && hostgroup.domain
              result << [host.name, hostgroup.domain.name].join('.')
            end
          end
          addresses.join(',')
        end

        def find_hostgroup(deployment, name)
          # locate the top-level hostgroup for the deployment...
          # currently, we'll create a hostgroup with the same name as the deployment...
          # Note: you need to scope the query to organization
          parent = ::Hostgroup.where(:name => deployment.name).
              joins(:organizations).
              where("taxonomies.id in (?)", [deployment.organization.id]).first

          # generate the ancestry, so that we can locate the hostgroups based on the hostgroup hierarchy, which assumes:
          # "Fusor Base"/"My Deployment"
          # Note: there may be a better way in foreman to locate the hostgroup
          if parent
            if parent.ancestry
              ancestry = [parent.ancestry, parent.id.to_s].join('/')
            else
              ancestry = parent.id.to_s
            end
          end

          # locate the engine hostgroup...
          ::Hostgroup.where(:name => name).
              where(:ancestry => ancestry).
              joins(:organizations).
              where("taxonomies.id in (?)", [deployment.organization.id]).first
        end
      end
    end
  end
end
