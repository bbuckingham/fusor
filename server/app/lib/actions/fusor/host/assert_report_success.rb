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
    module Host
      class AssertReportSuccess < Dynflow::Action

        middleware.use Actions::Fusor::Middleware::AsCurrentUser

        def plan(host_id)
          plan_self host_id: host_id
        end

        def run(event = nil)
          case event
          when Dynflow::Action::Skip
            output[:status] = true
          else
            output[:status] = assert_latest_report_success(input[:host_id])
          end
        end

        private

        def assert_latest_report_success(host_id)
          host   = ::Host.find(host_id)
          report = host.reports.order('reported_at DESC').first

          unless report
            fail(::Foreman::Exception, "No Puppet report found for host: #{host_id}")
          end

          check_for_failures(report, host_id)
          report_change?(report)
        end

        def report_change?(report)
          report.status['applied'] > 0
        end

        def check_for_failures(report, host_id)
          if report.status['failed'] > 0
            output[:report_id] = report.id
            fail(::Foreman::Exception, "Latest Puppet run contains failures for host: #{host_id}")
          end
        end

      end
    end
  end
end
